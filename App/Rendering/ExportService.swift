import SwiftUI
import AnattiCore

/// Renders every slide at every chosen size into a temporary folder laid out as
/// `<Store>/<WxH>/<NN>.png`. Files that fail validation are skipped, never written.
@MainActor
enum ExportService {
    struct Result {
        let folder: URL
        let written: Int
        let skipped: Int
    }

    static func export(
        project: Project,
        slides: [Slide],
        targets: [ScreenshotTarget],
        videos: [SourceAsset] = [],
        videoTargets: [VideoTarget] = [],
        store: LocalFileStore = .shared,
        progress: (Double) -> Void = { _ in }
    ) async throws -> Result {
        let fileManager = FileManager.default
        let folder = fileManager.temporaryDirectory
            .appendingPathComponent("Anatti-Export-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        let ordered = slides.sorted { $0.order < $1.order }
        let orderedVideos = videos.sorted { $0.createdAt < $1.createdAt }
        let total = max(ordered.count * targets.count + orderedVideos.count * videoTargets.count, 1)
        var done = 0, written = 0, skipped = 0

        for (slideIndex, slide) in ordered.enumerated() {
            let image = slide.sourceFilename.flatMap { try? store.load($0) }.flatMap(UIImage.init(data:))
            for target in targets {
                try Task.checkCancellation()
                let canvas = ScreenshotCanvas(
                    size: target.size, placement: slide.placement, title: slide.title,
                    subtitle: slide.subtitle, topHex: project.primaryColorHex,
                    bottomHex: project.secondaryColorHex, image: image)
                if let output = ScreenshotRenderer.render(canvas) {
                    for storeKind in Set(target.specs.map(\.store)) {
                        let specs = target.specs.filter { $0.store == storeKind }
                        let valid = specs.allSatisfy {
                            RenderValidator.validate(spec: $0, size: output.pixelSize, hasAlpha: output.hasAlpha,
                                                     format: .png, byteCount: output.png.count).isEmpty
                        }
                        guard valid else { skipped += 1; continue }
                        let path = ExportPlanner.relativePath(
                            item: ExportItem(store: storeKind, size: target.size), index: slideIndex + 1)
                        let url = folder.appendingPathComponent(path)
                        try fileManager.createDirectory(at: url.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                        try output.png.write(to: url, options: .atomic)
                        written += 1
                    }
                } else {
                    skipped += 1
                }
                done += 1
                progress(Double(done) / Double(total))
                await Task.yield()   // keep the UI responsive between renders
            }
        }

        for (videoIndex, asset) in orderedVideos.enumerated() {
            for target in videoTargets {
                try Task.checkCancellation()
                let url = folder.appendingPathComponent(
                    ExportPlanner.videoRelativePath(size: target.size, index: videoIndex + 1))
                try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                if await convertVideo(asset, to: target, output: url, store: store) {
                    written += 1
                } else {
                    skipped += 1
                }
                done += 1
                progress(Double(done) / Double(total))
            }
        }
        return Result(folder: folder, written: written, skipped: skipped)
    }

    /// Converts one video and removes the file again when it does not pass validation.
    private static func convertVideo(_ asset: SourceAsset, to target: VideoTarget, output: URL,
                                     store: LocalFileStore) async -> Bool {
        do {
            _ = try await VideoConverter.convert(source: store.url(for: asset.filename), target: target.size, to: output)
            let measured = try await VideoConverter.measure(output)
            let valid = measured.isH264 && target.specs.allSatisfy {
                VideoValidator.validate(spec: $0, size: measured.size, seconds: measured.seconds,
                                        frameRate: measured.frameRate, hasAudio: measured.hasAudio,
                                        format: .mp4, byteCount: measured.byteCount).isEmpty
            }
            if !valid { try? FileManager.default.removeItem(at: output) }
            return valid
        } catch {
            try? FileManager.default.removeItem(at: output)
            return false
        }
    }
}
