import Foundation
import CoreGraphics

/// Properties of a picked video, measured after applying its rotation.
public struct VideoSourceInfo: Equatable, Sendable {
    public let width: Double
    public let height: Double
    public let durationSeconds: Double
    public let frameRate: Double
    public let hasAudio: Bool

    public init(width: Double, height: Double, durationSeconds: Double, frameRate: Double, hasAudio: Bool) {
        self.width = width
        self.height = height
        self.durationSeconds = durationSeconds
        self.frameRate = frameRate
        self.hasAudio = hasAudio
    }
}

public enum VideoFit: String, Codable, Sendable, CaseIterable {
    /// Fills the frame and crops the overflow.
    case fill
    /// Shows the whole video and adds black bars.
    case fit
}

/// What the converter should do with one source video for one target size.
public struct VideoPlan: Equatable, Sendable {
    public let target: PixelSize
    /// How many times the source is played back to back (1 = once).
    public let loops: Int
    /// Seconds of the source used per loop.
    public let segmentSeconds: Double
    public let outputSeconds: Double
    public let frameRate: Int
    public let videoBitsPerSecond: Int
    /// No audio in the source: a silent stereo track is added.
    public let addsSilentAudio: Bool
    /// Scale and offset that map the displayed source onto the target frame.
    public let scale: Double
    public let offsetX: Double
    public let offsetY: Double
    /// Source and target are in different orientations, so fill mode crops a lot.
    public let orientationMismatch: Bool
}

public enum VideoPlanError: Error, Equatable, Sendable {
    case invalidSource
    case tooShort
}

public enum VideoPlanner {
    /// Apple wants 15-30 s. The margins keep rounding in the encoder from landing outside the range.
    public static let minOutputSeconds = 15.1
    public static let maxOutputSeconds = 29.9
    public static let minSourceSeconds = 1.0
    public static let videoBitsPerSecond = 11_000_000

    public static func plan(source: VideoSourceInfo, target: PixelSize, fit: VideoFit) throws -> VideoPlan {
        guard source.width > 0, source.height > 0, source.durationSeconds.isFinite, source.durationSeconds > 0 else {
            throw VideoPlanError.invalidSource
        }
        guard source.durationSeconds >= minSourceSeconds else { throw VideoPlanError.tooShort }

        let segment = min(source.durationSeconds, maxOutputSeconds)
        let loops = segment >= minOutputSeconds ? 1 : Int((minOutputSeconds / segment).rounded(.up))
        let output = min(segment * Double(loops), maxOutputSeconds)

        let rawFPS = source.frameRate.isFinite && source.frameRate > 0 ? source.frameRate : 30
        let fps = min(30, max(1, Int(rawFPS.rounded())))

        let tw = Double(target.width), th = Double(target.height)
        let sx = tw / source.width, sy = th / source.height
        let scale = fit == .fill ? max(sx, sy) : min(sx, sy)

        return VideoPlan(
            target: target, loops: loops, segmentSeconds: segment, outputSeconds: output,
            frameRate: fps, videoBitsPerSecond: videoBitsPerSecond,
            addsSilentAudio: !source.hasAudio, scale: scale,
            offsetX: (tw - source.width * scale) / 2, offsetY: (th - source.height * scale) / 2,
            orientationMismatch: (source.width > source.height) != (target.width > target.height))
    }
}

public enum VideoIssue: Hashable, Sendable {
    case wrongSize
    case tooShort
    case tooLong
    case frameRateTooHigh
    case fileTooLarge(maxMB: Int)
    case noAudio
    case unsupportedFormat
}

public enum VideoValidator {
    /// Allowed rounding slack on the duration, in seconds.
    static let tolerance = 0.05

    public static func validate(spec: AssetSpec, size: PixelSize, seconds: Double, frameRate: Double,
                                hasAudio: Bool, format: FileFormat, byteCount: Int,
                                limits: VideoLimits = VideoLimits()) -> [VideoIssue] {
        var issues: [VideoIssue] = []
        if !spec.accepts(size) { issues.append(.wrongSize) }
        if seconds < Double(limits.minSeconds) - tolerance { issues.append(.tooShort) }
        if seconds > Double(limits.maxSeconds) + tolerance { issues.append(.tooLong) }
        if frameRate > Double(limits.maxFPS) + 0.5 { issues.append(.frameRateTooHigh) }
        if byteCount > limits.maxFileMB * 1_000_000 { issues.append(.fileTooLarge(maxMB: limits.maxFileMB)) }
        if !hasAudio { issues.append(.noAudio) }
        if !spec.formats.contains(format) { issues.append(.unsupportedFormat) }
        return issues
    }
}

public extension VideoLimits {
    /// H.264 level 4.0 allows at most 8192 macroblocks (16x16) per frame.
    static func fitsH264Level40(_ size: PixelSize) -> Bool {
        ((size.width + 15) / 16) * ((size.height + 15) / 16) <= 8192
    }
}

public extension ExportPlanner {
    static func videoRelativePath(size: PixelSize, index: Int) -> String {
        let number = index < 10 ? "0\(index)" : "\(index)"
        return "\(folderName(for: .appStore))/Previews/\(size.width)x\(size.height)/\(number).mp4"
    }
}
