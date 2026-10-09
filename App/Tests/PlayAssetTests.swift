import Testing
import SwiftUI
import AnattiCore
@testable import Anatti

@MainActor
@Suite struct PlayAssetTests {
    private func iconImage(noisy: Bool = false) -> UIImage {
        guard noisy else {
            return UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300)).image { context in
                UIColor.systemOrange.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
            }
        }
        // Photo-like: smooth gradient plus fine noise. Compresses badly as PNG, well as JPEG.
        let side = 512
        var generator = SystemRandomNumberGenerator()
        var pixels = [UInt8](repeating: 255, count: side * side * 4)
        for y in 0..<side {
            for x in 0..<side {
                let base = (x + y) * 255 / (2 * side)
                let i = (y * side + x) * 4
                for channel in 0..<3 {
                    let noise = Int.random(in: -6...6, using: &generator)
                    pixels[i + channel] = UInt8(clamping: base + channel * 40 + noise)
                }
            }
        }
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        let cg = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
                         space: CGColorSpace(name: CGColorSpace.sRGB)!,
                         bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                         provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        return UIImage(cgImage: cg, scale: 1, orientation: .up)
    }

    private func project() -> Project {
        Project(name: "Habit Tracker", tagline: "Simple. Private.")
    }

    @Test func everyPlayAssetIsValid() throws {
        for asset in PlayAsset.allCases {
            let output = try #require(PlayAssetRenderer.render(asset, project: project(), icon: iconImage()))
            #expect(output.pixelSize == asset.size, "\(asset)")
            let issues = RenderValidator.validate(spec: asset.spec, size: output.pixelSize, hasAlpha: output.hasAlpha,
                                                  format: output.format, byteCount: output.data.count)
            #expect(issues.isEmpty, "\(asset): \(issues)")
        }
    }

    @Test func graphicsRenderWithoutIcon() throws {
        let output = try #require(PlayAssetRenderer.render(.featureGraphic, project: project(), icon: nil))
        #expect(output.pixelSize == PixelSize(1024, 500) && !output.hasAlpha)
    }

    @Test func oversizedPNGFallsBackToJPEG() throws {
        let canvas = IconCanvas(size: PixelSize(512, 512), backgroundHex: "#0A84FF", image: iconImage(noisy: true))
        let png = try #require(ScreenshotRenderer.render(canvas))
        #expect(png.format == .png)
        let limit = 150_000
        #expect(png.data.count > limit, "png \(png.data.count)")
        let jpeg = try #require(ScreenshotRenderer.render(canvas, maxBytes: limit))
        #expect(jpeg.format == .jpeg && jpeg.data.count <= limit, "\(jpeg.format) \(jpeg.data.count)")
        #expect(jpeg.pixelSize == PixelSize(512, 512) && !jpeg.hasAlpha)
    }

    @Test func exportWritesPlayGraphics() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("store-\(UUID().uuidString)")
        let store = LocalFileStore(directory: directory)
        defer { try? FileManager.default.removeItem(at: directory) }
        let project = project()
        project.appIconFilename = try store.save(try #require(iconImage().pngData()), fileExtension: "png")

        let result = try await ExportService.export(project: project, slides: [], targets: [],
                                                    playAssets: PlayAsset.allCases, store: store)
        defer { try? FileManager.default.removeItem(at: result.folder) }

        #expect(result.written == 3 && result.skipped == 0)
        for path in ["GooglePlay/Icon/512x512.png", "GooglePlay/FeatureGraphic/1024x500.png",
                     "GooglePlay/TVBanner/1280x720.png"] {
            #expect(FileManager.default.fileExists(atPath: result.folder.appendingPathComponent(path).path), "\(path)")
        }
    }
}
