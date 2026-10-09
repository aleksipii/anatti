import Foundation

/// Kauppojen materiaalivaatimukset. Lähteet: docs/SPECS.md.
/// Tarkista Applen ja Googlen sivuilta aina ennen julkaisua, koot muuttuvat.
public enum SpecCatalog {
    private static let img: [FileFormat] = [.png, .jpeg]
    private static let vid: [FileFormat] = [.mov, .m4v, .mp4]

    private static func shot(_ id: String, _ device: String, _ sizes: [PixelSize],
                             required: Bool = false, notes: String = "") -> AssetSpec {
        AssetSpec(id: id, store: .appStore, kind: .screenshot, deviceClass: device,
                  sizes: sizes, landscapeToo: true, required: required,
                  minCount: 1, maxCount: 10, formats: img, allowsAlpha: false, notes: notes)
    }

    private static func preview(_ id: String, _ device: String, _ sizes: [PixelSize],
                                notes: String = "") -> AssetSpec {
        AssetSpec(id: id, store: .appStore, kind: .preview, deviceClass: device,
                  sizes: sizes, landscapeToo: true, required: false,
                  minCount: 0, maxCount: 3, formats: vid, allowsAlpha: false, notes: notes)
    }

    // MARK: App Store – kuvakaappaukset (pystykoot, vaaka = käännetty)

    public static let appStoreScreenshots: [AssetSpec] = [
        shot("as.shot.iphone.duo.outer", "iPhone Duo (ulkonäyttö)", [PixelSize(1398, 2034)],
             notes: "Pakollinen huhtikuusta 2027 iOS 27.1 SDK:lla rakennetuille"),
        shot("as.shot.iphone.duo.inner", "iPhone Duo (sisänäyttö)", [PixelSize(2007, 2853)],
             notes: "Pakollinen huhtikuusta 2027 iOS 27.1 SDK:lla rakennetuille"),
        shot("as.shot.iphone.di.large", "iPhone Dynamic Island, large",
             [PixelSize(1260, 2736), PixelSize(1290, 2796), PixelSize(1320, 2868)]),
        shot("as.shot.iphone.faceid.large", "iPhone Face ID, large",
             [PixelSize(1284, 2778), PixelSize(1242, 2688)]),
        shot("as.shot.iphone.di.medium", "iPhone Dynamic Island, medium (6,1\" / 6,3\")",
             [PixelSize(1179, 2556), PixelSize(1206, 2622)], required: true),
        shot("as.shot.iphone.faceid.medium", "iPhone Face ID, medium",
             [PixelSize(1170, 2532), PixelSize(1125, 2436), PixelSize(1080, 2340)]),
        shot("as.shot.iphone.home.large", "iPhone Home Button, large", [PixelSize(1242, 2208)]),
        shot("as.shot.iphone.home.medium", "iPhone Home Button, medium", [PixelSize(750, 1334)]),
        shot("as.shot.iphone.home.4in", "iPhone Home Button, 4\"",
             [PixelSize(640, 1096), PixelSize(640, 1136)]),
        shot("as.shot.iphone.home.3_5in", "iPhone Home Button, 3,5\"",
             [PixelSize(640, 920), PixelSize(640, 960)]),
        shot("as.shot.ipad.13", "iPad 13\"", [PixelSize(2064, 2752), PixelSize(2048, 2732)],
             required: true, notes: "Pakollinen jos sovellus toimii iPadilla"),
        shot("as.shot.ipad.12_9", "iPad 12,9\" (2. sukupolvi)", [PixelSize(2048, 2732)]),
        shot("as.shot.ipad.11", "iPad 11\"",
             [PixelSize(1488, 2266), PixelSize(1668, 2420), PixelSize(1668, 2388), PixelSize(1640, 2360)]),
        shot("as.shot.ipad.10_5", "iPad 10,5\"", [PixelSize(1668, 2224)]),
        shot("as.shot.ipad.9_7", "iPad 9,7\"",
             [PixelSize(1536, 2008), PixelSize(1536, 2048), PixelSize(768, 1004), PixelSize(768, 1024)]),
    ]

    /// Muut Applen alustat. Vain vaakakoot, ei käännettäviä pystykokoja.
    public static let appStoreOtherPlatforms: [AssetSpec] = [
        AssetSpec(id: "as.shot.mac", store: .appStore, kind: .screenshot, deviceClass: "Mac (16:10)",
                  sizes: [PixelSize(1280, 800), PixelSize(1440, 900), PixelSize(2560, 1600), PixelSize(2880, 1800)],
                  landscapeToo: false, required: false, minCount: 1, maxCount: 10,
                  formats: img, allowsAlpha: false, notes: "Valitse yksi koko"),
        AssetSpec(id: "as.shot.tv", store: .appStore, kind: .screenshot, deviceClass: "Apple TV",
                  sizes: [PixelSize(1920, 1080), PixelSize(3840, 2160)],
                  landscapeToo: false, required: false, minCount: 1, maxCount: 10,
                  formats: img, allowsAlpha: false, notes: ""),
        AssetSpec(id: "as.shot.vision", store: .appStore, kind: .screenshot, deviceClass: "Apple Vision Pro",
                  sizes: [PixelSize(3840, 2160)],
                  landscapeToo: false, required: false, minCount: 1, maxCount: 10,
                  formats: img, allowsAlpha: false, notes: ""),
        AssetSpec(id: "as.shot.watch", store: .appStore, kind: .screenshot, deviceClass: "Apple Watch",
                  sizes: [PixelSize(422, 514), PixelSize(410, 502), PixelSize(416, 496),
                          PixelSize(396, 484), PixelSize(368, 448), PixelSize(312, 390)],
                  landscapeToo: false, required: false, minCount: 1, maxCount: 10,
                  formats: img, allowsAlpha: false,
                  notes: "Yksi koko mallia kohti, sama kaikissa kielissä"),
    ]

    // MARK: App Store – App Preview -videot

    public static let appStorePreviews: [AssetSpec] = [
        preview("as.prev.iphone.duo", "iPhone Duo", [PixelSize(886, 1920)]),
        preview("as.prev.iphone.di.large", "iPhone Dynamic Island, large", [PixelSize(886, 1920)]),
        preview("as.prev.iphone.faceid.large", "iPhone Face ID, large", [PixelSize(886, 1920)]),
        preview("as.prev.iphone.di.medium", "iPhone Dynamic Island, medium", [PixelSize(886, 1920)]),
        preview("as.prev.iphone.faceid.medium", "iPhone Face ID, medium", [PixelSize(886, 1920)]),
        preview("as.prev.iphone.home.large", "iPhone Home Button, large", [PixelSize(1080, 1920)]),
        preview("as.prev.iphone.home.medium", "iPhone Home Button, medium", [PixelSize(750, 1334)]),
        preview("as.prev.iphone.home.4in", "iPhone Home Button, 4\"", [PixelSize(1080, 1920)]),
        preview("as.prev.ipad.13", "iPad 13\"", [PixelSize(1200, 1600)]),
        preview("as.prev.ipad.12_9", "iPad 12,9\" (2. sukupolvi)", [PixelSize(1200, 1600), PixelSize(900, 1200)]),
        preview("as.prev.ipad.11", "iPad 11\"", [PixelSize(1200, 1600)]),
        preview("as.prev.ipad.10_5", "iPad 10,5\"", [PixelSize(1200, 1600)]),
        preview("as.prev.ipad.9_7", "iPad 9,7\"", [PixelSize(900, 1200)]),
        AssetSpec(id: "as.prev.mac", store: .appStore, kind: .preview, deviceClass: "Mac",
                  sizes: [PixelSize(1920, 1080)], landscapeToo: false, required: false,
                  minCount: 0, maxCount: 3, formats: vid, allowsAlpha: false, notes: "Vain vaaka"),
        AssetSpec(id: "as.prev.tv", store: .appStore, kind: .preview, deviceClass: "Apple TV",
                  sizes: [PixelSize(1920, 1080)], landscapeToo: false, required: false,
                  minCount: 0, maxCount: 3, formats: vid, allowsAlpha: false, notes: "Vain vaaka"),
        AssetSpec(id: "as.prev.vision", store: .appStore, kind: .preview, deviceClass: "Apple Vision Pro",
                  sizes: [PixelSize(3840, 2160)], landscapeToo: false, required: false,
                  minCount: 0, maxCount: 3, formats: vid, allowsAlpha: false, notes: "Vain vaaka"),
    ]

    // MARK: App Store – Product Page Optimization (kuvakaappaukset App Store Connectista)

    public static let appStorePPO: [AssetSpec] = [
        AssetSpec(id: "as.ppo.header", store: .appStore, kind: .ppoHeader, deviceClass: "PPO Header",
                  sizes: [PixelSize(5244, 2950), PixelSize(3840, 1646)],
                  landscapeToo: false, required: false, minCount: 0, maxCount: 1,
                  formats: img, allowsAlpha: false, notes: "Vaakakoko, ei käännetä"),
        AssetSpec(id: "as.ppo.search", store: .appStore, kind: .ppoSearchResults, deviceClass: "PPO Search Results",
                  sizes: [PixelSize(5244, 2950), PixelSize(3840, 2560), PixelSize(1920, 1280)],
                  landscapeToo: false, required: false, minCount: 0, maxCount: 1,
                  formats: img, allowsAlpha: false, notes: "Vaakakoko, ei käännetä"),
    ]

    // MARK: Play Store (Play Consolen omat vaatimukset)

    private static let ratios16x9 = [PixelSize(16, 9), PixelSize(9, 16)]

    private static func playShot(_ id: String, _ device: String, sides: ClosedRange<Int>,
                                 min: Int, max: Int = 8, mb: Int = 8, notes: String = "",
                                 recommended: PixelSize) -> AssetSpec {
        AssetSpec(id: id, store: .playStore, kind: .screenshot, deviceClass: device,
                  sizes: [recommended], landscapeToo: true, required: min > 0,
                  minCount: min, maxCount: max, formats: img, allowsAlpha: false, notes: notes,
                  sideRange: sides, aspectRatios: ratios16x9, maxFileMB: mb)
    }

    public static let playStore: [AssetSpec] = [
        AssetSpec(id: "gp.icon", store: .playStore, kind: .icon, deviceClass: "Sovelluskuvake",
                  sizes: [PixelSize(512, 512)], landscapeToo: false, required: true,
                  minCount: 1, maxCount: 1, formats: img, allowsAlpha: true,
                  notes: "Noudata kuvakesuunnittelun määrityksiä ja metadatakäytäntöä",
                  maxFileMB: 1),
        AssetSpec(id: "gp.feature", store: .playStore, kind: .featureGraphic, deviceClass: "Ominaisuuskuva",
                  sizes: [PixelSize(1024, 500)], landscapeToo: false, required: true,
                  minCount: 1, maxCount: 1, formats: img, allowsAlpha: false,
                  notes: "Pidä sisältö keskellä, reunat voidaan rajata", maxFileMB: 15),
        playShot("gp.shot.phone", "Puhelin", sides: 320...3840, min: 2,
                 recommended: PixelSize(1080, 1920)),
        playShot("gp.shot.tablet7", "7\" tabletti", sides: 320...3840, min: 0,
                 recommended: PixelSize(1080, 1920)),
        playShot("gp.shot.tablet10", "10\" tabletti", sides: 1080...7680, min: 0,
                 recommended: PixelSize(1200, 1920)),
        playShot("gp.shot.desktop", "Työpöytä (Chromebook)", sides: 1080...7680, min: 4,
                 notes: "Vaaditaan vain jos sovellus tukee työpöytää",
                 recommended: PixelSize(1920, 1080)),
        playShot("gp.shot.xr", "Android XR", sides: 720...7680, min: 4, mb: 15,
                 notes: "Vaaditaan vain jos sovellus tukee XR:ää",
                 recommended: PixelSize(1920, 1080)),
        AssetSpec(id: "gp.shot.wear", store: .playStore, kind: .screenshot, deviceClass: "Wear OS",
                  sizes: [PixelSize(384, 384)], landscapeToo: false, required: false,
                  minCount: 1, maxCount: 8, formats: img, allowsAlpha: false,
                  notes: "Kolmas osapuoli: 1:1, väh. 384×384, ei kehyksiä. VAHVISTA"),
        AssetSpec(id: "gp.shot.tv", store: .playStore, kind: .screenshot, deviceClass: "Android TV",
                  sizes: [PixelSize(1920, 1080)], landscapeToo: false, required: false,
                  minCount: 1, maxCount: 8, formats: img, allowsAlpha: false,
                  notes: "Kolmas osapuoli: 16:9. VAHVISTA"),
        AssetSpec(id: "gp.banner.tv", store: .playStore, kind: .banner, deviceClass: "Android TV -banneri",
                  sizes: [PixelSize(1280, 720)], landscapeToo: false, required: false,
                  minCount: 0, maxCount: 1, formats: img, allowsAlpha: false,
                  notes: "Kolmas osapuoli. VAHVISTA"),
        AssetSpec(id: "gp.shot.auto", store: .playStore, kind: .screenshot, deviceClass: "Android Automotive OS",
                  sizes: [PixelSize(800, 1280), PixelSize(1024, 768)], landscapeToo: false, required: false,
                  minCount: 2, maxCount: 8, formats: img, allowsAlpha: false,
                  notes: "Kolmas osapuoli: 2 pysty + 2 vaaka. VAHVISTA"),
    ]

    public static var all: [AssetSpec] {
        appStoreScreenshots + appStoreOtherPlatforms + appStorePreviews + appStorePPO + playStore
    }

    public static func specs(store: Store, kind: AssetKind) -> [AssetSpec] {
        all.filter { $0.store == store && $0.kind == kind }
    }
}
