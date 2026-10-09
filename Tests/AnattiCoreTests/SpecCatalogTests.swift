import Testing
@testable import AnattiCore

@Suite struct SpecCatalogTests {
    @Test func idsAreUnique() {
        let ids = SpecCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func requiredAppStoreSizesPresent() {
        let di = SpecCatalog.appStoreScreenshots.first { $0.id == "as.shot.iphone.di.medium" }
        #expect(di?.accepts(PixelSize(1206, 2622)) == true)
        #expect(di?.accepts(PixelSize(2622, 1206)) == true)
        let ipad = SpecCatalog.appStoreScreenshots.first { $0.id == "as.shot.ipad.13" }
        #expect(ipad?.accepts(PixelSize(2064, 2752)) == true)
    }

    @Test func previewDurationLimits() {
        let limits = VideoLimits()
        #expect(limits.minSeconds == 15 && limits.maxSeconds == 30)
    }
}
