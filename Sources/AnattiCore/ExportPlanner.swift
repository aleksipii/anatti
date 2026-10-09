import Foundation

public struct ExportItem: Hashable, Sendable {
    public let store: Store
    public let size: PixelSize
    /// Optional folder between the store and the size, e.g. "PPO".
    public let subfolder: String?

    public init(store: Store, size: PixelSize, subfolder: String? = nil) {
        self.store = store
        self.size = size
        self.subfolder = subfolder
    }
}

public struct ExportEntry: Hashable, Sendable {
    public let item: ExportItem
    /// 1-based position of the slide in the set.
    public let index: Int
    /// Relative to the export root, e.g. "AppStore/1206x2622/01.png".
    public let relativePath: String
}

public enum ExportWarning: Hashable, Sendable {
    /// More slides than the smallest per-size maximum of the chosen specs.
    case tooMany(max: Int, have: Int)
    /// Fewer slides than a required spec's minimum.
    case tooFew(min: Int, have: Int)
}

/// Decides where exported files go and what to warn about. Pure, so it is testable on any platform.
public enum ExportPlanner {
    public static func folderName(for store: Store) -> String {
        switch store {
        case .appStore: "AppStore"
        case .playStore: "GooglePlay"
        }
    }

    public static func relativePath(item: ExportItem, index: Int) -> String {
        let number = index < 10 ? "0\(index)" : "\(index)"
        let parent = [folderName(for: item.store), item.subfolder].compactMap { $0 }.joined(separator: "/")
        return "\(parent)/\(item.size.width)x\(item.size.height)/\(number).png"
    }

    public static func entries(slideCount: Int, items: [ExportItem]) -> [ExportEntry] {
        guard slideCount > 0 else { return [] }
        return items.flatMap { item in
            (1...slideCount).map {
                ExportEntry(item: item, index: $0, relativePath: relativePath(item: item, index: $0))
            }
        }
    }

    public static func warnings(slideCount: Int, specs: [AssetSpec]) -> [ExportWarning] {
        // PPO sizes hold one image per product page test, so the count limit does not apply to them.
        let specs = specs.filter { !$0.kind.isPPO }
        var result: [ExportWarning] = []
        if let max = specs.map(\.maxCount).min(), slideCount > max {
            result.append(.tooMany(max: max, have: slideCount))
        }
        if let min = specs.filter(\.required).map(\.minCount).max(), slideCount < min {
            result.append(.tooFew(min: min, have: slideCount))
        }
        return result
    }
}

public extension AssetKind {
    var isPPO: Bool { self == .ppoHeader || self == .ppoSearchResults }
}
