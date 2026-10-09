import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    /// File name (inside LocalFileStore) of the user's app icon, if any.
    var appIconFilename: String?
    /// Short line shown next to the name on Play graphics.
    var tagline: String = ""
    /// Colors stored as "#RRGGBB".
    var primaryColorHex: String
    var secondaryColorHex: String
    /// Language codes, e.g. ["en", "fi"].
    var languages: [String]
    /// Selected AnattiCore spec IDs.
    var selectedSpecIDs: [String]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        appIconFilename: String? = nil,
        tagline: String = "",
        primaryColorHex: String = "#0A84FF",
        secondaryColorHex: String = "#5E5CE6",
        languages: [String] = ["en"],
        selectedSpecIDs: [String] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.appIconFilename = appIconFilename
        self.tagline = tagline
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.languages = languages
        self.selectedSpecIDs = selectedSpecIDs
    }
}

extension Project {
    /// The first language is the default for all slide text.
    var baseLanguage: String { languages.first ?? "en" }
}
