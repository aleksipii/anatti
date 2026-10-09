import Testing
@testable import AnattiCore

@Suite struct ExportPlannerTests {
    @Test func pathsAreStableAndPadded() {
        let item = ExportItem(store: .appStore, size: PixelSize(1206, 2622))
        #expect(ExportPlanner.relativePath(item: item, index: 1) == "AppStore/1206x2622/01.png")
        #expect(ExportPlanner.relativePath(item: item, index: 10) == "AppStore/1206x2622/10.png")
        let play = ExportItem(store: .playStore, size: PixelSize(1080, 1920))
        #expect(ExportPlanner.relativePath(item: play, index: 2) == "GooglePlay/1080x1920/02.png")
    }

    @Test func entriesCoverEverySlideAndItem() {
        let items = [ExportItem(store: .appStore, size: PixelSize(1206, 2622)),
                     ExportItem(store: .playStore, size: PixelSize(1080, 1920))]
        let entries = ExportPlanner.entries(slideCount: 3, items: items)
        #expect(entries.count == 6)
        #expect(Set(entries.map(\.relativePath)).count == 6)
        #expect(ExportPlanner.entries(slideCount: 0, items: items).isEmpty)
    }

    @Test func warnsAboutCounts() {
        let appStore = SpecCatalog.appStoreScreenshots.first { $0.id == "as.shot.iphone.di.medium" }!
        #expect(ExportPlanner.warnings(slideCount: 11, specs: [appStore]) == [.tooMany(max: 10, have: 11)])
        #expect(ExportPlanner.warnings(slideCount: 5, specs: [appStore]).isEmpty)
        let phone = SpecCatalog.playStore.first { $0.id == "gp.shot.phone" }!
        #expect(ExportPlanner.warnings(slideCount: 1, specs: [phone]) == [.tooFew(min: 2, have: 1)])
    }
}
