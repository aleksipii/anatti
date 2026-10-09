import Testing
import SwiftUI
import AnattiCore
@testable import Anatti

@MainActor
@Suite struct ScreenshotRendererTests {
    private func canvas(_ size: PixelSize, placement: TextPlacement = .top) -> ScreenshotCanvas {
        ScreenshotCanvas(size: size, placement: placement, title: "Headline", subtitle: "Caption",
                         topHex: "#0A84FF", bottomHex: "#5E5CE6", image: nil)
    }

    @Test func rendersExactPixelsWithoutAlpha() throws {
        let size = PixelSize(1206, 2622)
        let output = try #require(ScreenshotRenderer.render(canvas(size)))
        #expect(output.pixelSize == size)
        #expect(!output.hasAlpha)
    }

    @Test func rendersLandscapeAndPlayRanges() throws {
        for size in [PixelSize(2622, 1206), PixelSize(1080, 1920), PixelSize(1920, 1080)] {
            let output = try #require(ScreenshotRenderer.render(canvas(size, placement: .bottom)))
            #expect(output.pixelSize == size)
            #expect(!output.hasAlpha)
        }
    }

    @Test func outputPassesValidatorForEverySize() throws {
        for target in ScreenshotTarget.all.prefix(6) {
            let output = try #require(ScreenshotRenderer.render(canvas(target.size)))
            for spec in target.specs {
                let issues = RenderValidator.validate(spec: spec, size: output.pixelSize, hasAlpha: output.hasAlpha,
                                                      format: .png, byteCount: output.data.count)
                #expect(issues.isEmpty, "\(spec.id) \(target.size.label): \(issues)")
            }
        }
    }

    @Test func rendersLargestPPOSize() throws {
        let target = try #require(ScreenshotTarget.all.first { $0.size == PixelSize(5244, 2950) })
        let output = try #require(ScreenshotRenderer.render(canvas(target.size)))
        #expect(output.pixelSize == target.size && !output.hasAlpha)
        for spec in target.specs {
            #expect(RenderValidator.validate(spec: spec, size: output.pixelSize, hasAlpha: output.hasAlpha,
                                             format: output.format, byteCount: output.data.count).isEmpty)
        }
    }
}
