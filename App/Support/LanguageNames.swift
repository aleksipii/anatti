import Foundation

/// Language name in the user's current UI language, e.g. "suomi" shown as "Finnish" in English.
func languageName(_ code: String) -> String {
    Locale.current.localizedString(forLanguageCode: code)?.localizedCapitalized ?? code
}
