import Foundation
import AnattiCore

/// A pixel size the user can render, with every screenshot spec that accepts it.
struct ScreenshotTarget: Identifiable, Hashable {
    let size: PixelSize
    let specs: [AssetSpec]
    var id: PixelSize { size }
    var isRequired: Bool { specs.contains(where: \.required) }
    /// Product Page Optimization sizes (header and search results images).
    var isPPO: Bool { specs.allSatisfy { $0.kind.isPPO } }

    /// All screenshot and PPO sizes. Screenshots first, required sizes before optional ones.
    static let all: [ScreenshotTarget] = {
        var specsBySize: [PixelSize: [AssetSpec]] = [:]
        for spec in SpecCatalog.all where spec.kind == .screenshot || spec.kind.isPPO {
            for size in spec.renderSizes { specsBySize[size, default: []].append(spec) }
        }
        return specsBySize
            .map { ScreenshotTarget(size: $0.key, specs: $0.value) }
            .sorted {
                if $0.isPPO != $1.isPPO { return !$0.isPPO }
                if $0.isRequired != $1.isRequired { return $0.isRequired }
                if $0.size.height != $1.size.height { return $0.size.height > $1.size.height }
                return $0.size.width > $1.size.width
            }
    }()

    static let `default`: ScreenshotTarget = all.first { $0.size == PixelSize(1206, 2622) } ?? all[0]
}
