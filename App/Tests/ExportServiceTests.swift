import Testing
import SwiftUI
import AnattiCore
@testable import Anatti

@MainActor
@Suite struct ExportServiceTests {
    @Test func writesValidFilesPerStoreAndSize() async throws {
        let project = Project(name: "Test")
        let slides = [Slide(projectID: project.id, order: 0, title: "One"),
                      Slide(projectID: project.id, order: 1, title: "Two")]
        let sizes = [PixelSize(1206, 2622), PixelSize(1080, 1920)]
        let targets = ScreenshotTarget.all.filter { sizes.contains($0.size) }
        #expect(targets.count == 2)

        let result = try await ExportService.export(project: project, slides: slides, targets: targets)
        defer { try? FileManager.default.removeItem(at: result.folder) }

        #expect(result.skipped == 0)
        #expect(result.written > 0)
        let expected = ["AppStore/1206x2622/01.png", "AppStore/1206x2622/02.png",
                        "GooglePlay/1080x1920/01.png", "GooglePlay/1080x1920/02.png"]
        for path in expected {
            let data = try Data(contentsOf: result.folder.appendingPathComponent(path))
            let image = try #require(UIImage(data: data))
            let parts = path.split(separator: "/")[1].split(separator: "x").compactMap { Int($0) }
            #expect(Int(image.size.width * image.scale) == parts[0], "\(path)")
            #expect(Int(image.size.height * image.scale) == parts[1], "\(path)")
        }
    }
}
