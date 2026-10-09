import Foundation

public struct RGB: Hashable, Sendable {
    public let r: Double
    public let g: Double
    public let b: Double

    public init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    /// Relative luminance (WCAG), 0 = black, 1 = white.
    public var luminance: Double {
        func lin(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    }

    /// True when white text reads better than black on this color.
    public var prefersLightText: Bool { luminance < 0.4 }
}

/// Colors are stored as "#RRGGBB".
public enum HexColor {
    public static func parse(_ hex: String) -> RGB? {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        return RGB(r: Double((value >> 16) & 0xFF) / 255,
                   g: Double((value >> 8) & 0xFF) / 255,
                   b: Double(value & 0xFF) / 255)
    }

    public static func format(_ rgb: RGB) -> String {
        func byte(_ c: Double) -> Int { Int((min(max(c, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(rgb.r), byte(rgb.g), byte(rgb.b))
    }
}
