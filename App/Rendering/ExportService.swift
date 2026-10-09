import SwiftUI
import AnattiCore

/// Renders every slide at every chosen size into a temporary folder laid out as
/// `<Store>[/<language>]/<WxH>/<NN>.png`. Files that fail validation are skipped, never written.
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
        playAssets: [PlayAsset] = [],
        store: LocalFileStore = .shared,
        progress: (Double) -> Void = { _ in }
    ) async throws -> Result {
        let fileManager = FileManager.default
        let folder = fileManager.temporaryDirectory
            .appendingPathComponent("Anatti-Export-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        let ordered = slides.sorted { $0.order < $1.order }
        let orderedVideos = videos.sorted { $0.createdAt < $1.createdAt }
        // One folder per language when the project has several; single-language projects stay flat.
        let languageCodes: [String?] = project.languages.count > 1 ? project.languages : [nil]
        let total = max(ordered.count * targets.count * languageCodes.count + orderedVideos.count * videoTargets.count + playAssets.count, 1)
        var done = 0, written = 0, skipped = 0

        for languageCode in languageCodes {
            for (slideIndex, slide) in ordered.enumerated() {
                let image = slide.sourceFilename.flatMap { try? store.load($0) }.flatMap(UIImage.init(data:))
                let text = slide.resolvedText(language: languageCode ?? project.baseLanguage,
                                              baseLanguage: project.baseLanguage)
                for target in targets {
                    try Task.checkCancellation()
                    let canvas = ScreenshotCanvas(
                        size: target.size, placement: slide.placement, title: text.title,
                        subtitle: text.subtitle, topHex: project.primaryColorHex,
                        bottomHex: project.secondaryColorHex, image: image)
                    if let output = ScreenshotRenderer.render(canvas) {
                        for storeKind in Set(target.specs.map(\.store)) {
                            let specs = target.specs.filter { $0.store == storeKind }
                            let valid = specs.allSatisfy {
                                RenderValidator.validate(spec: $0, size: output.pixelSize, hasAlpha: output.hasAlpha,
                                                         format: .png, byteCount: output.data.count).isEmpty
                            }
                            guard valid else { skipped += 1; continue }
                            let item = ExportItem(
                                store: storeKind, size: target.size, subfolder: target.isPPO ? "PPO" : nil,
                                language: languageCode.map(SupportedLanguage.exportFolder(forCode:)))
                            let url = folder.appendingPathComponent(
                                ExportPlanner.relativePath(item: item, index: slideIndex + 1))
                            try fileManager.createDirectory(at: url.deletingLastPathComponent(),
                                                            withIntermediateDirectories: true)
                            try output.data.write(to: url, options: .atomic)
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

        if !playAssets.isEmpty {
            let icon = project.appIconFilename.flatMap { try? store.load($0) }.flatMap(UIImage.init(data:))
            for asset in playAssets {
                try Task.checkCancellation()
                let output = PlayAssetRenderer.render(asset, project: project, icon: icon)
                if let output,
                   RenderValidator.validate(spec: asset.spec, size: output.pixelSize, hasAlpha: output.hasAlpha,
                                            format: output.format, byteCount: output.data.count).isEmpty {
                    let path = ExportPlanner.brandAssetPath(
                        kind: asset.spec.kind, size: output.pixelSize,
                        fileExtension: output.format == .jpeg ? "jpg" : "png")
                    let url = folder.appendingPathComponent(path)
                    try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try output.data.write(to: url, options: .atomic)
                    written += 1
                } else {
                    skipped += 1
                }
                done += 1
                progress(Double(done) / Double(total))
                await Task.yield()
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
