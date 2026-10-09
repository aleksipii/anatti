import Testing
import CoreGraphics
@testable import AnattiCore

@Suite struct BrandLayoutTests {
    private let sizes = [PixelSize(1024, 500), PixelSize(1280, 720)]

    @Test func contentStaysInSafeArea() {
        for size in sizes {
            for hasIcon in [true, false] {
                let layout = BrandLayout(canvas: size, hasIcon: hasIcon)
                let canvas = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                #expect(canvas.contains(layout.safeArea))
                #expect(layout.safeArea.contains(layout.textFrame), "\(size.label) text")
                #expect(layout.textFrame.width > 0)
                if let icon = layout.iconFrame {
                    #expect(hasIcon)
                    #expect(layout.safeArea.contains(icon), "\(size.label) icon")
                    #expect(!icon.intersects(layout.textFrame))
                    #expect(icon.width == icon.height)
                } else {
                    #expect(!hasIcon)
                }
            }
        }
    }

    @Test func playGraphicSpecsMatchCatalog() {
        let feature = SpecCatalog.playStore.first { $0.id == "gp.feature" }!
        #expect(feature.sizes == [PixelSize(1024, 500)])
        let icon = SpecCatalog.playStore.first { $0.id == "gp.icon" }!
        #expect(icon.sizes == [PixelSize(512, 512)] && icon.allowsAlpha)
    }

    @Test func textColorAndPaths() {
        #expect(HexColor.prefersLightText(topHex: "#0A84FF", bottomHex: "#5E5CE6"))
        #expect(!HexColor.prefersLightText(topHex: "#FFFFFF", bottomHex: "#F0F0F0"))
        #expect(ExportPlanner.brandAssetPath(kind: .featureGraphic, size: PixelSize(1024, 500), fileExtension: "png")
                == "GooglePlay/FeatureGraphic/1024x500.png")
        #expect(ExportPlanner.brandAssetPath(kind: .icon, size: PixelSize(512, 512), fileExtension: "jpg")
                == "GooglePlay/Icon/512x512.jpg")
    }
}
