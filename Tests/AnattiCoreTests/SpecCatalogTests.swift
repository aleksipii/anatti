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

    @Test func playRangesAndRatios() {
        let phone = SpecCatalog.playStore.first { $0.id == "gp.shot.phone" }
        #expect(phone?.accepts(PixelSize(1080, 1920)) == true)
        #expect(phone?.accepts(PixelSize(3840, 2160)) == true)
        #expect(phone?.accepts(PixelSize(1080, 2400)) == false)   // ei 16:9
        #expect(phone?.accepts(PixelSize(180, 320)) == false)     // alle 320 px
        let tablet10 = SpecCatalog.playStore.first { $0.id == "gp.shot.tablet10" }
        #expect(tablet10?.accepts(PixelSize(720, 1280)) == false) // alle 1080 px
        #expect(tablet10?.maxFileMB == 8)
    }
}
