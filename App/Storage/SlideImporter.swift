import SwiftUI
import SwiftData

/// Turns several picked images into slides in one go, keeping the pick order.
@MainActor
enum SlideImporter {
    /// Creates one slide per readable image and returns how many were created.
    /// Unreadable data is skipped, so the count can be lower than `images.count`.
    @discardableResult
    static func importSlides(
        _ images: [Data], project: Project, startOrder: Int,
        context: ModelContext, store: LocalFileStore = .shared
    ) -> Int {
        var imported = 0
        for data in images {
            guard let image = UIImage(data: data),
                  let name = try? store.save(image.pngData() ?? data, fileExtension: "png") else { continue }
            context.insert(Slide(projectID: project.id, order: startOrder + imported, sourceFilename: name))
            imported += 1
        }
        return imported
    }
}
