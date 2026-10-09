import Testing
import Foundation
import CoreGraphics
@testable import AnattiCore

@Suite struct RenderTests {
    @Test func hexRoundTrip() {
        let rgb = HexColor.parse("#0A84FF")
        #expect(rgb != nil)
        #expect(HexColor.format(rgb!) == "#0A84FF")
        #expect(HexColor.parse("zzzzzz") == nil)
        #expect(HexColor.parse("#FFF") == nil)
    }

    @Test func textContrast() {
        #expect(HexColor.parse("#000000")!.prefersLightText)
        #expect(!HexColor.parse("#FFFFFF")!.prefersLightText)
    }

    @Test func layoutStaysInsideCanvas() {
        for spec in SpecCatalog.all where spec.kind == .screenshot {
            for size in spec.renderSizes {
                for placement in TextPlacement.allCases {
                    let layout = ScreenshotLayout(canvas: size, placement: placement)
                    let canvas = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                    #expect(canvas.contains(layout.textFrame), "\(spec.id) \(size.label) text")
                    #expect(canvas.contains(layout.imageFrame), "\(spec.id) \(size.label) image")
                    #expect(!layout.textFrame.intersects(layout.imageFrame), "\(spec.id) \(size.label) overlap")
                }
            }
        }
    }

    @Test func everyRenderSizeIsAccepted() {
        for spec in SpecCatalog.all {
            #expect(!spec.renderSizes.isEmpty, "\(spec.id)")
            for size in spec.renderSizes { #expect(spec.accepts(size)) }
        }
    }

    @Test func validatorFlagsProblems() {
        let spec = SpecCatalog.appStoreScreenshots.first { $0.id == "as.shot.iphone.di.medium" }!
        let ok = RenderValidator.validate(spec: spec, size: PixelSize(1206, 2622),
                                          hasAlpha: false, format: .png, byteCount: 1000)
        #expect(ok.isEmpty)
        let bad = RenderValidator.validate(spec: spec, size: PixelSize(100, 100),
                                           hasAlpha: true, format: .mp4, byteCount: 1000)
        #expect(Set(bad) == [.wrongSize, .hasAlpha, .unsupportedFormat])
        let play = SpecCatalog.playStore.first { $0.id == "gp.feature" }!
        let big = RenderValidator.validate(spec: play, size: PixelSize(1024, 500),
                                           hasAlpha: false, format: .png, byteCount: 16_000_000)
        #expect(big == [.fileTooLarge(maxMB: 15)])
    }
}
