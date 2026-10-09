import SwiftUI
import AnattiCore

extension Color {
    /// Creates a color from "#RRGGBB". Falls back to gray when the string is invalid.
    init(hex: String) {
        let rgb = HexColor.parse(hex) ?? RGB(r: 0.5, g: 0.5, b: 0.5)
        self.init(.sRGB, red: rgb.r, green: rgb.g, blue: rgb.b, opacity: 1)
    }

    /// "#RRGGBB" in sRGB, ignoring opacity.
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return HexColor.format(RGB(r: Double(r), g: Double(g), b: Double(b)))
    }
}
