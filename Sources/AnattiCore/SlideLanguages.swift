import Foundation

/// Languages Anatti supports for slide text. Raw values match the project's language codes.
public enum SupportedLanguage: String, CaseIterable, Codable, Sendable {
    case en, es, de, fi, sv, fr, it

    /// Folder name used when a project exports more than one language.
    public var exportFolder: String {
        switch self {
        case .en: "en-US"
        case .es: "es-ES"
        case .de: "de-DE"
        case .fi: "fi"
        case .sv: "sv"
        case .fr: "fr-FR"
        case .it: "it"
        }
    }

    public static func exportFolder(forCode code: String) -> String {
        SupportedLanguage(rawValue: code)?.exportFolder ?? code
    }
}

public struct SlideText: Codable, Equatable, Sendable {
    public var title: String
    public var subtitle: String

    public init(title: String = "", subtitle: String = "") {
        self.title = title
        self.subtitle = subtitle
    }
}

/// Per-language slide text. The slide's own title and caption belong to the project's first
/// language; other languages are overrides. An empty field falls back to the base text.
public enum SlideTexts {
    public static func decode(_ json: String) -> [String: SlideText] {
        guard let data = json.data(using: .utf8),
              let map = try? JSONDecoder().decode([String: SlideText].self, from: data) else { return [:] }
        return map
    }

    public static func encode(_ map: [String: SlideText]) -> String {
        let cleaned = map.filter { !$0.value.title.isEmpty || !$0.value.subtitle.isEmpty }
        guard let data = try? JSONEncoder().encode(cleaned), let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    public static func resolve(language: String, baseLanguage: String, base: SlideText,
                               overrides: [String: SlideText]) -> SlideText {
        guard language != baseLanguage, let own = overrides[language] else { return base }
        return SlideText(title: own.title.isEmpty ? base.title : own.title,
                         subtitle: own.subtitle.isEmpty ? base.subtitle : own.subtitle)
    }
}
