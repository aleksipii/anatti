import Foundation

public enum RenderIssue: Hashable, Sendable {
    case wrongSize
    case hasAlpha
    case fileTooLarge(maxMB: Int)
    case unsupportedFormat
}

public extension AssetSpec {
    /// Every pixel size the spec accepts that we can render exactly.
    /// For range-based Play specs this is the recommended size and its rotation.
    var renderSizes: [PixelSize] {
        var seen = Set<PixelSize>()
        return allAcceptedSizes.filter { accepts($0) && seen.insert($0).inserted }
    }
}

/// Checks a rendered file against a spec before it is exported.
public enum RenderValidator {
    public static func validate(spec: AssetSpec, size: PixelSize, hasAlpha: Bool,
                                format: FileFormat, byteCount: Int) -> [RenderIssue] {
        var issues: [RenderIssue] = []
        if !spec.accepts(size) { issues.append(.wrongSize) }
        if hasAlpha && !spec.allowsAlpha { issues.append(.hasAlpha) }
        if !spec.formats.contains(format) { issues.append(.unsupportedFormat) }
        if let maxMB = spec.maxFileMB, byteCount > maxMB * 1_000_000 {
            issues.append(.fileTooLarge(maxMB: maxMB))
        }
        return issues
    }
}
