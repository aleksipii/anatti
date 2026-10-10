import Testing
import SwiftUI
import SwiftData
@testable import Anatti

@MainActor
@Suite struct SlideImporterTests {
    private func png(_ color: UIColor) -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 40, height: 80)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 80))
        }.pngData()!
    }

    @Test func createsOrderedSlidesAndSkipsUnreadable() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("import-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LocalFileStore(directory: directory)
        let container = try ModelContainer(
            for: Project.self, Slide.self, SourceAsset.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let project = Project(name: "Bulk")
        context.insert(project)

        let imported = SlideImporter.importSlides(
            [png(.red), Data("not an image".utf8), png(.blue)],
            project: project, startOrder: 3, context: context, store: store)

        #expect(imported == 2)
        let slides = try context.fetch(FetchDescriptor<Slide>(sortBy: [SortDescriptor(\.order)]))
        #expect(slides.map(\.order) == [3, 4])
        #expect(slides.allSatisfy { $0.projectID == project.id })
        for slide in slides {
            let name = try #require(slide.sourceFilename)
            #expect(store.exists(name))
        }
    }
}
