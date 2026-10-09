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
        store: LocalFileStore = .shared,
        progress: (Double) -> Void = { _ in }
    ) async throws -> Result {
        let fileManager = FileManager.default
        let folder = fileManager.temporaryDirectory
            .appendingPathComponent("Anatti-Export-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        let ordered = slides.sorted { $0.order < $1.order }
        let total = max(ordered.count * targets.count, 1)
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
        return Result(folder: folder, written: written, skipped: skipped)
    }
}
