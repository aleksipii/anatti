import Foundation
import AnattiCore

/// An App Preview size the user can export, with every spec that accepts it.
struct VideoTarget: Identifiable, Hashable {
    let size: PixelSize
    let specs: [AssetSpec]
    var id: PixelSize { size }

    /// App Preview sizes that H.264 level 4.0 can encode (excludes Vision Pro 4K).
    static let all: [VideoTarget] = {
        var specsBySize: [PixelSize: [AssetSpec]] = [:]
        for spec in SpecCatalog.appStorePreviews {
            for size in spec.renderSizes where VideoLimits.fitsH264Level40(size) {
                specsBySize[size, default: []].append(spec)
            }
        }
        return specsBySize
            .map { VideoTarget(size: $0.key, specs: $0.value) }
            .sorted { ($0.size.height, $0.size.width) > ($1.size.height, $1.size.width) }
    }()
}
