import Foundation

public enum Store: String, Codable, Sendable, CaseIterable {
    case appStore, playStore
}

public enum AssetKind: String, Codable, Sendable, CaseIterable {
    case screenshot, preview, icon, featureGraphic, banner
    case ppoHeader, ppoSearchResults
}

public enum FileFormat: String, Codable, Sendable {
    case png, jpeg, mov, m4v, mp4
}

public struct PixelSize: Hashable, Codable, Sendable {
    public let width: Int
    public let height: Int

    public init(_ width: Int, _ height: Int) {
        self.width = width
        self.height = height
    }

    public var isPortrait: Bool { height > width }
    public var swapped: PixelSize { PixelSize(height, width) }
    public var label: String { "\(width) × \(height)" }
}

/// Yksi vientikohde: tietty kauppa, laiteluokka ja materiaalityyppi.
public struct AssetSpec: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let store: Store
    public let kind: AssetKind
    public let deviceClass: String
    /// Hyväksytyt koot pystyssä. Vaakakoot saadaan `swapped`-kentällä, ellei `portraitOnly`.
    public let sizes: [PixelSize]
    public let landscapeToo: Bool
    public let required: Bool
    public let minCount: Int
    public let maxCount: Int
    public let formats: [FileFormat]
    public let allowsAlpha: Bool
    public let notes: String
    /// Play Console: sallittu pituus kummallekin sivulle (ei kiinteitä kokoja).
    public var sideRange: ClosedRange<Int>? = nil
    /// Play Console: sallitut kuvasuhteet (leveys, korkeus), pysty- ja vaakasuunta.
    public var aspectRatios: [PixelSize] = []
    public var maxFileMB: Int? = nil

    public var allAcceptedSizes: [PixelSize] {
        landscapeToo ? sizes + sizes.map(\.swapped) : sizes
    }

    public func accepts(_ size: PixelSize) -> Bool {
        if let range = sideRange {
            guard range.contains(size.width), range.contains(size.height) else { return false }
            return aspectRatios.contains { $0.width * size.height == $0.height * size.width }
        }
        return allAcceptedSizes.contains(size)
    }
}

/// Videon yhteiset rajat (Apple App Preview).
public struct VideoLimits: Sendable {
    public let minSeconds = 15
    public let maxSeconds = 30
    public let maxFPS = 30
    public let maxFileMB = 500
    public let h264MbpsRange = 10...12
    public let audio = "Stereo AAC 256 kbps, 44,1 tai 48 kHz"
    public init() {}
}
