import Foundation
import SwiftData
import AnattiCore

/// One screenshot design: a source screenshot plus headline and caption.
/// Colors come from the owning `Project`, so a whole set shares one look.
@Model
final class Slide {
    @Attribute(.unique) var id: UUID
    var projectID: UUID
    var order: Int
    var title: String
    var subtitle: String
    var placementRaw: String
    /// JSON of per-language overrides, see `SlideTexts`. The title/subtitle above belong to the project's first language.
    var textsJSON: String = "{}"
    /// File name inside LocalFileStore.
    var sourceFilename: String?

    init(
        id: UUID = UUID(),
        projectID: UUID,
        order: Int,
        title: String = "",
        subtitle: String = "",
        placement: TextPlacement = .top,
        sourceFilename: String? = nil
    ) {
        self.id = id
        self.projectID = projectID
        self.order = order
        self.title = title
        self.subtitle = subtitle
        self.placementRaw = placement.rawValue
        self.sourceFilename = sourceFilename
    }

    var placement: TextPlacement {
        get { TextPlacement(rawValue: placementRaw) ?? .top }
        set { placementRaw = newValue.rawValue }
    }
}

extension Slide {
    /// What the user typed for this language: the slide's own fields for the base language, otherwise its override.
    func rawText(language: String, baseLanguage: String) -> SlideText {
        if language == baseLanguage { return SlideText(title: title, subtitle: subtitle) }
        return SlideTexts.decode(textsJSON)[language] ?? SlideText()
    }

    func setRawText(_ text: SlideText, language: String, baseLanguage: String) {
        if language == baseLanguage {
            title = text.title
            subtitle = text.subtitle
        } else {
            var map = SlideTexts.decode(textsJSON)
            map[language] = text
            textsJSON = SlideTexts.encode(map)
        }
    }

    /// Text to draw for a language, falling back to the base language per field.
    func resolvedText(language: String, baseLanguage: String) -> SlideText {
        SlideTexts.resolve(language: language, baseLanguage: baseLanguage,
                           base: SlideText(title: title, subtitle: subtitle),
                           overrides: SlideTexts.decode(textsJSON))
    }
}

extension ModelContext {
    /// Deletes a slide and its stored screenshot file.
    func deleteSlide(_ slide: Slide, store: LocalFileStore = .shared) {
        if let name = slide.sourceFilename { try? store.delete(name) }
        delete(slide)
    }

    /// Deletes a source video and its stored file.
    func deleteVideo(_ asset: SourceAsset, store: LocalFileStore = .shared) {
        try? store.delete(asset.filename)
        delete(asset)
    }

    /// Deletes a project together with its slides and their files.
    func deleteProject(_ project: Project, store: LocalFileStore = .shared) {
        let id = project.id
        let descriptor = FetchDescriptor<Slide>(predicate: #Predicate { $0.projectID == id })
        for slide in (try? fetch(descriptor)) ?? [] { deleteSlide(slide, store: store) }
        let assetDescriptor = FetchDescriptor<SourceAsset>(predicate: #Predicate { $0.projectID == id })
        for asset in (try? fetch(assetDescriptor)) ?? [] { deleteVideo(asset, store: store) }
        if let icon = project.appIconFilename { try? store.delete(icon) }
        delete(project)
    }
}
