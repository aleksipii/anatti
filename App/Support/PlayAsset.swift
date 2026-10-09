import SwiftUI
import AnattiCore

/// The single-file Google Play graphics Anatti can generate from project data.
enum PlayAsset: String, CaseIterable, Identifiable {
    case icon, featureGraphic, tvBanner

    var id: String { rawValue }

    var spec: AssetSpec {
        let specID: String
        switch self {
        case .icon: specID = "gp.icon"
        case .featureGraphic: specID = "gp.feature"
        case .tvBanner: specID = "gp.banner.tv"
        }
        return SpecCatalog.playStore.first { $0.id == specID }!
    }

    var size: PixelSize { spec.sizes[0] }
    var needsIcon: Bool { self == .icon }

    var titleKey: LocalizedStringKey {
        switch self {
        case .icon: "play.icon"
        case .featureGraphic: "play.feature"
        case .tvBanner: "play.banner"
        }
    }
}

@MainActor
enum PlayAssetRenderer {
    static func render(_ asset: PlayAsset, project: Project, icon: UIImage?) -> ScreenshotRenderer.Output? {
        let maxBytes = asset.spec.maxFileMB.map { $0 * 1_000_000 }
        switch asset {
        case .icon:
            return ScreenshotRenderer.render(
                IconCanvas(size: asset.size, backgroundHex: project.primaryColorHex, image: icon), maxBytes: maxBytes)
        case .featureGraphic, .tvBanner:
            return ScreenshotRenderer.render(
                BrandCanvas(size: asset.size, title: project.name, tagline: project.tagline,
                            topHex: project.primaryColorHex, bottomHex: project.secondaryColorHex, icon: icon),
                maxBytes: maxBytes)
        }
    }
}
