import Foundation
import CoreGraphics

public enum TextPlacement: String, Codable, Sendable, CaseIterable {
    case top, bottom
}

/// Geometry of one screenshot slide, in pixels of the target canvas.
/// Pure maths so every size can be checked without rendering.
public struct ScreenshotLayout: Equatable, Sendable {
    public let canvas: PixelSize
    public let textFrame: CGRect
    public let imageFrame: CGRect
    public let titleFontSize: Double
    public let subtitleFontSize: Double
    public let cornerRadius: Double
    /// Landscape canvases put the text on the left and the screenshot on the right.
    public let isSideBySide: Bool

    public init(canvas: PixelSize, placement: TextPlacement) {
        self.canvas = canvas
        let w = Double(canvas.width)
        let h = Double(canvas.height)
        let margin = min(w, h) * 0.06
        isSideBySide = !canvas.isPortrait && canvas.width != canvas.height

        if isSideBySide {
            let textWidth = w * 0.38
            textFrame = CGRect(x: margin, y: margin, width: textWidth - margin, height: h - 2 * margin)
            imageFrame = CGRect(x: textWidth + margin, y: margin,
                                width: w - textWidth - 2 * margin, height: h - 2 * margin)
            titleFontSize = min(h * 0.09, textWidth * 0.2)
        } else {
            let band = h * 0.26
            let textY = placement == .top ? margin : h - band
            textFrame = CGRect(x: margin, y: textY, width: w - 2 * margin, height: band - margin)
            let imageY = placement == .top ? band : margin
            imageFrame = CGRect(x: margin, y: imageY, width: w - 2 * margin, height: h - band - margin)
            titleFontSize = w * 0.075
        }
        subtitleFontSize = titleFontSize * 0.52
        cornerRadius = min(w, h) * 0.04
    }
}
