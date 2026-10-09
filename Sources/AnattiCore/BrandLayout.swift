import Foundation
import CoreGraphics

/// Layout of the wide Play graphics (feature graphic, TV banner): app icon on the left,
/// name and tagline on the right. Everything stays inside a safe area because Google Play
/// may crop the edges.
public struct BrandLayout: Equatable, Sendable {
    public let canvas: PixelSize
    public let safeArea: CGRect
    public let iconFrame: CGRect?
    public let textFrame: CGRect
    public let titleFontSize: Double
    public let taglineFontSize: Double
    public let iconCornerRadius: Double

    public init(canvas: PixelSize, hasIcon: Bool) {
        self.canvas = canvas
        let w = Double(canvas.width)
        let h = Double(canvas.height)
        let safe = CGRect(x: w * 0.1, y: h * 0.12, width: w * 0.8, height: h * 0.76)
        safeArea = safe

        var textX = safe.minX
        if hasIcon {
            let side = safe.height * 0.7
            let frame = CGRect(x: safe.minX, y: safe.midY - side / 2, width: side, height: side)
            iconFrame = frame
            iconCornerRadius = side * 0.22
            textX = frame.maxX + w * 0.04
        } else {
            iconFrame = nil
            iconCornerRadius = 0
        }
        textFrame = CGRect(x: textX, y: safe.minY, width: safe.maxX - textX, height: safe.height)
        titleFontSize = h * 0.13
        taglineFontSize = titleFontSize * 0.5
    }
}

public extension HexColor {
    /// True when white text reads better than black on the average of two background colors.
    static func prefersLightText(topHex: String, bottomHex: String) -> Bool {
        let top = parse(topHex) ?? RGB(r: 0, g: 0, b: 0)
        let bottom = parse(bottomHex) ?? RGB(r: 0, g: 0, b: 0)
        return RGB(r: (top.r + bottom.r) / 2, g: (top.g + bottom.g) / 2, b: (top.b + bottom.b) / 2)
            .prefersLightText
    }
}

public extension ExportPlanner {
    /// Single-file Play graphics, e.g. "GooglePlay/FeatureGraphic/1024x500.png".
    static func brandAssetPath(kind: AssetKind, size: PixelSize, fileExtension: String) -> String {
        let folder: String
        switch kind {
        case .icon: folder = "Icon"
        case .featureGraphic: folder = "FeatureGraphic"
        case .banner: folder = "TVBanner"
        default: folder = kind.rawValue
        }
        return "\(folderName(for: .playStore))/\(folder)/\(size.width)x\(size.height).\(fileExtension)"
    }
}
