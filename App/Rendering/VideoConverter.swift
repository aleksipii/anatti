import AVFoundation
import AnattiCore

struct VideoMeasurement: Sendable {
    let size: PixelSize
    let seconds: Double
    let frameRate: Double
    let hasAudio: Bool
    let byteCount: Int
    let isH264: Bool
}

enum VideoConverterError: Error {
    case noVideoTrack
    case cannotRead
    case cannotWrite
    case failed(Error?)
}

/// Converts a picked video into an App Store preview: exact size, 15-30 s, at most 30 fps,
/// H.264 High 4.0 at about 11 Mbps and stereo AAC 256 kbps at 48 kHz.
enum VideoConverter {
    private static let sampleRate = 48_000.0

    /// Reads what the planner needs from a source file.
    static func inspect(_ url: URL) async throws -> VideoSourceInfo {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoConverterError.noVideoTrack
        }
        let (naturalSize, transform, fps) = try await track.load(.naturalSize, .preferredTransform, .nominalFrameRate)
        let duration = try await asset.load(.duration).seconds
        let hasAudio = try await !asset.loadTracks(withMediaType: .audio).isEmpty
        let shown = CGRect(origin: .zero, size: naturalSize).applying(transform)
        return VideoSourceInfo(width: abs(shown.width), height: abs(shown.height),
                               durationSeconds: duration, frameRate: Double(fps), hasAudio: hasAudio)
    }

    /// Reads back what the finished file really contains, so validation does not trust the plan.
    static func measure(_ url: URL) async throws -> VideoMeasurement {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoConverterError.noVideoTrack
        }
        let (size, transform, fps, formats) = try await track.load(
            .naturalSize, .preferredTransform, .nominalFrameRate, .formatDescriptions)
        let shown = CGRect(origin: .zero, size: size).applying(transform)
        let hasAudio = try await !asset.loadTracks(withMediaType: .audio).isEmpty
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let isH264 = formats.contains { CMFormatDescriptionGetMediaSubType($0) == kCMVideoCodecType_H264 }
        return VideoMeasurement(
            size: PixelSize(Int(abs(shown.width).rounded()), Int(abs(shown.height).rounded())),
            seconds: try await asset.load(.duration).seconds, frameRate: Double(fps),
            hasAudio: hasAudio, byteCount: bytes, isH264: isH264)
    }

    @concurrent
    static func convert(
        source: URL, target: PixelSize, fit: VideoFit = .fill, to output: URL,
        progress: @Sendable (Double) -> Void = { _ in }
    ) async throws -> VideoPlan {
        let info = try await inspect(source)
        let plan = try VideoPlanner.plan(source: info, target: target, fit: fit)

        let asset = AVURLAsset(url: source)
        guard let sourceVideo = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoConverterError.noVideoTrack
        }
        let preferred = try await sourceVideo.load(.preferredTransform)
        let sourceAudio = try await asset.loadTracks(withMediaType: .audio).first
        let sourceDuration = try await asset.load(.duration)

        // Composition: the source repeated `loops` times, cut to the planned length.
        let composition = AVMutableComposition()
        guard let video = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else { throw VideoConverterError.cannotRead }

        let total = CMTime(seconds: plan.outputSeconds, preferredTimescale: 600)
        let segment = CMTime(seconds: min(plan.segmentSeconds, sourceDuration.seconds), preferredTimescale: 600)
        var cursor = CMTime.zero
        while cursor < total {
            let length = min(segment, total - cursor)
            let range = CMTimeRange(start: .zero, duration: length)
            try video.insertTimeRange(range, of: sourceVideo, at: cursor)
            if let sourceAudio { try? audio.insertTimeRange(range, of: sourceAudio, at: cursor) }
            cursor = cursor + length
        }

        var silentURL: URL?
        defer { if let silentURL { try? FileManager.default.removeItem(at: silentURL) } }
        if plan.addsSilentAudio {
            let url = try makeSilentAudio(seconds: plan.outputSeconds)
            silentURL = url
            let silent = AVURLAsset(url: url)
            if let track = try await silent.loadTracks(withMediaType: .audio).first {
                try audio.insertTimeRange(CMTimeRange(start: .zero, duration: total), of: track, at: .zero)
            }
        }

        // Rotation first, then scale and center into the target frame.
        let transform = preferred
            .concatenating(CGAffineTransform(scaleX: plan.scale, y: plan.scale))
            .concatenating(CGAffineTransform(translationX: plan.offsetX, y: plan.offsetY))
        var layerConfiguration = AVVideoCompositionLayerInstruction.Configuration(assetTrack: video)
        layerConfiguration.setTransform(transform, at: .zero)
        var instructionConfiguration = AVVideoCompositionInstruction.Configuration()
        instructionConfiguration.timeRange = CMTimeRange(start: .zero, duration: total)
        instructionConfiguration.layerInstructions = [AVVideoCompositionLayerInstruction(configuration: layerConfiguration)]
        instructionConfiguration.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        var compositionConfiguration = AVVideoComposition.Configuration()
        compositionConfiguration.renderSize = CGSize(width: target.width, height: target.height)
        compositionConfiguration.frameDuration = CMTime(value: 1, timescale: CMTimeScale(plan.frameRate))
        compositionConfiguration.instructions = [AVVideoCompositionInstruction(configuration: instructionConfiguration)]
        let videoComposition = AVVideoComposition(configuration: compositionConfiguration)

        // Reader
        let reader = try AVAssetReader(asset: composition)
        let videoOut = AVAssetReaderVideoCompositionOutput(
            videoTracks: [video],
            videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        videoOut.videoComposition = videoComposition
        let audioOut = AVAssetReaderAudioMixOutput(audioTracks: [audio], audioSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: sampleRate, AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsNonInterleaved: false])
        guard reader.canAdd(videoOut), reader.canAdd(audioOut) else { throw VideoConverterError.cannotRead }
        reader.add(videoOut)
        reader.add(audioOut)

        // Writer
        try? FileManager.default.removeItem(at: output)
        let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
        let videoIn = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: target.width, AVVideoHeightKey: target.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: plan.videoBitsPerSecond,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
                AVVideoMaxKeyFrameIntervalKey: plan.frameRate * 2,
                AVVideoExpectedSourceFrameRateKey: plan.frameRate,
            ]])
        let audioIn = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 256_000])
        guard writer.canAdd(videoIn), writer.canAdd(audioIn) else { throw VideoConverterError.cannotWrite }
        writer.add(videoIn)
        writer.add(audioIn)

        guard reader.startReading(), writer.startWriting() else {
            throw VideoConverterError.failed(reader.error ?? writer.error)
        }
        writer.startSession(atSourceTime: .zero)

        do {
            var videoDone = false, audioDone = false
            while !(videoDone && audioDone) {
                try Task.checkCancellation()
                var moved = false
                if !videoDone, videoIn.isReadyForMoreMediaData {
                    if let buffer = videoOut.copyNextSampleBuffer() {
                        guard videoIn.append(buffer) else { throw VideoConverterError.failed(writer.error) }
                        progress(min(CMSampleBufferGetPresentationTimeStamp(buffer).seconds / plan.outputSeconds, 1))
                    } else {
                        videoIn.markAsFinished()
                        videoDone = true
                    }
                    moved = true
                }
                if !audioDone, audioIn.isReadyForMoreMediaData {
                    if let buffer = audioOut.copyNextSampleBuffer() {
                        guard audioIn.append(buffer) else { throw VideoConverterError.failed(writer.error) }
                    } else {
                        audioIn.markAsFinished()
                        audioDone = true
                    }
                    moved = true
                }
                if !moved { try await Task.sleep(for: .milliseconds(5)) }
            }
            if reader.status == .failed { throw VideoConverterError.failed(reader.error) }
            await writer.finishWriting()
            guard writer.status == .completed else { throw VideoConverterError.failed(writer.error) }
        } catch {
            reader.cancelReading()
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: output)
            throw error
        }
        progress(1)
        return plan
    }

    /// Writes a silent stereo file to use as the audio track of videos that have none.
    private static func makeSilentAudio(seconds: Double) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("silence-\(UUID().uuidString).caf")
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            throw VideoConverterError.cannotWrite
        }
        let frames = AVAudioFrameCount(seconds * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let channels = buffer.floatChannelData else { throw VideoConverterError.cannotWrite }
        buffer.frameLength = frames
        for channel in 0..<Int(format.channelCount) {
            channels[channel].update(repeating: 0, count: Int(frames))
        }
        let file = try AVAudioFile(forWriting: url, settings: format.settings,
                                   commonFormat: .pcmFormatFloat32, interleaved: false)
        try file.write(from: buffer)
        return url
    }
}
