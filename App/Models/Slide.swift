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

extension ModelContext {
    /// Deletes a slide and its stored screenshot file.
    func deleteSlide(_ slide: Slide, store: LocalFileStore = .shared) {
        if let name = slide.sourceFilename { try? store.delete(name) }
        delete(slide)
    }

    /// Deletes a project together with its slides and their files.
    func deleteProject(_ project: Project, store: LocalFileStore = .shared) {
        let id = project.id
        let descriptor = FetchDescriptor<Slide>(predicate: #Predicate { $0.projectID == id })
        for slide in (try? fetch(descriptor)) ?? [] { deleteSlide(slide, store: store) }
        if let icon = project.appIconFilename { try? store.delete(icon) }
        delete(project)
    }
}
