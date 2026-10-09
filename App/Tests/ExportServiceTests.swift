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

    @Test func exportsConvertedVideo() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("store-\(UUID().uuidString)")
        let store = LocalFileStore(directory: directory)
        let source = try await TestVideo.make(seconds: 4, fps: 30)
        let name = try store.importFile(at: source)
        defer { try? FileManager.default.removeItem(at: directory); try? FileManager.default.removeItem(at: source) }

        let project = Project(name: "Video")
        let asset = SourceAsset(projectID: project.id, filename: name, kind: .video)
        let target = try #require(VideoTarget.all.first { $0.size == PixelSize(886, 1920) })

        let result = try await ExportService.export(project: project, slides: [], targets: [],
                                                    videos: [asset], videoTargets: [target], store: store)
        defer { try? FileManager.default.removeItem(at: result.folder) }

        #expect(result.written == 1 && result.skipped == 0)
        let file = result.folder.appendingPathComponent("AppStore/Previews/886x1920/01.mp4")
        let measured = try await VideoConverter.measure(file)
        #expect(measured.size == PixelSize(886, 1920) && measured.hasAudio && measured.isH264)
    }

    @Test func exportsPPOImagesToOwnFolder() async throws {
        let project = Project(name: "PPO")
        let slides = [Slide(projectID: project.id, order: 0, title: "One"),
                      Slide(projectID: project.id, order: 1, title: "Two")]
        let target = try #require(ScreenshotTarget.all.first { $0.size == PixelSize(1920, 1280) })
        #expect(target.isPPO)

        let result = try await ExportService.export(project: project, slides: slides, targets: [target])
        defer { try? FileManager.default.removeItem(at: result.folder) }

        #expect(result.written == 2 && result.skipped == 0)
        for number in ["01", "02"] {
            let file = result.folder.appendingPathComponent("AppStore/PPO/1920x1280/\(number).png")
            let image = try #require(UIImage(data: try Data(contentsOf: file)))
            #expect(Int(image.size.width * image.scale) == 1920 && Int(image.size.height * image.scale) == 1280)
        }
    }

    @Test func exportsOneFolderPerLanguage() async throws {
        let project = Project(name: "Lang", languages: ["en", "fi"])
        let slide = Slide(projectID: project.id, order: 0, title: "Track habits", subtitle: "Simple")
        slide.setRawText(SlideText(title: "Seuraa tapoja", subtitle: ""), language: "fi", baseLanguage: "en")
        let target = try #require(ScreenshotTarget.all.first { $0.size == PixelSize(1206, 2622) })

        let result = try await ExportService.export(project: project, slides: [slide], targets: [target])
        defer { try? FileManager.default.removeItem(at: result.folder) }

        #expect(result.written == 2 && result.skipped == 0)
        let english = try Data(contentsOf: result.folder.appendingPathComponent("AppStore/en-US/1206x2622/01.png"))
        let finnish = try Data(contentsOf: result.folder.appendingPathComponent("AppStore/fi/1206x2622/01.png"))
        #expect(english != finnish, "the Finnish image must use the Finnish text")
    }

    @Test func singleLanguageStaysFlat() async throws {
        let project = Project(name: "One")
        let slide = Slide(projectID: project.id, order: 0, title: "A")
        let target = try #require(ScreenshotTarget.all.first { $0.size == PixelSize(1206, 2622) })
        let result = try await ExportService.export(project: project, slides: [slide], targets: [target])
        defer { try? FileManager.default.removeItem(at: result.folder) }
        #expect(FileManager.default.fileExists(atPath: result.folder.appendingPathComponent("AppStore/1206x2622/01.png").path))
    }
}
