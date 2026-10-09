import Foundation

/// Product identifiers for Anatti Pro (see docs/CONTRACT.md).
public enum ProProduct {
    public static let groupName = "anatti_pro"
    public static let monthlyID = "fi.anatti.pro.monthly"
}

/// All external links used by the paywall live here. PLACEHOLDERS: replace before release
/// (App Store requires working Terms of Use and Privacy Policy links).
public enum PaywallLinks {
    public static let terms = URL(string: "https://anatti.example/terms")!
    public static let privacy = URL(string: "https://anatti.example/privacy")!
}

/// Localization helper. DECISION: the String Catalog (`Localizable.xcstrings`) lives in the
/// APP target, so strings are resolved from the main bundle (the default bundle of
/// `Text(LocalizedStringKey)` / `String(localized:)`), never `Bundle.module`.
/// All AnattiPro UI goes through this one helper.
enum ProL10n {
    static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: .main)
    }
}
