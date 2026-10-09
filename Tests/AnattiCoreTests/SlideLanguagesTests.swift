import Testing
@testable import AnattiCore

@Suite struct SlideLanguagesTests {
    @Test func foldersMatchStoreLocales() {
        #expect(SupportedLanguage.en.exportFolder == "en-US")
        #expect(SupportedLanguage.fi.exportFolder == "fi")
        #expect(SupportedLanguage.exportFolder(forCode: "xx") == "xx")
        #expect(Set(SupportedLanguage.allCases.map(\.exportFolder)).count == SupportedLanguage.allCases.count)
    }

    @Test func jsonRoundTripDropsEmptyEntries() {
        let map = ["fi": SlideText(title: "Otsikko", subtitle: ""), "de": SlideText()]
        let decoded = SlideTexts.decode(SlideTexts.encode(map))
        #expect(decoded == ["fi": SlideText(title: "Otsikko", subtitle: "")])
        #expect(SlideTexts.decode("not json").isEmpty)
        #expect(SlideTexts.decode("").isEmpty)
    }

    @Test func resolveFallsBackPerField() {
        let base = SlideText(title: "Track habits", subtitle: "Simple")
        let overrides = ["fi": SlideText(title: "Seuraa tapoja", subtitle: "")]
        #expect(SlideTexts.resolve(language: "en", baseLanguage: "en", base: base, overrides: overrides) == base)
        #expect(SlideTexts.resolve(language: "fi", baseLanguage: "en", base: base, overrides: overrides)
                == SlideText(title: "Seuraa tapoja", subtitle: "Simple"))
        #expect(SlideTexts.resolve(language: "de", baseLanguage: "en", base: base, overrides: overrides) == base)
    }

    @Test func languageFolderInPath() {
        let item = ExportItem(store: .appStore, size: PixelSize(1206, 2622), language: "de-DE")
        #expect(ExportPlanner.relativePath(item: item, index: 1) == "AppStore/de-DE/1206x2622/01.png")
        let ppo = ExportItem(store: .appStore, size: PixelSize(1920, 1280), subfolder: "PPO", language: "fi")
        #expect(ExportPlanner.relativePath(item: ppo, index: 2) == "AppStore/fi/PPO/1920x1280/02.png")
    }
}
