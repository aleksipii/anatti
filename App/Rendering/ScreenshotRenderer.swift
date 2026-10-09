import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import AnattiCore

/// Renders a `ScreenshotCanvas` to an opaque PNG at its exact pixel size.
@MainActor
enum ScreenshotRenderer {
    struct Output {
        let png: Data
        let pixelSize: PixelSize
        /// Read back from the encoded PNG, not assumed.
        let hasAlpha: Bool
    }

    static func render(_ canvas: ScreenshotCanvas) -> Output? {
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 1
        renderer.isOpaque = true
        guard let rendered = renderer.cgImage, let opaque = flatten(rendered) else { return nil }
        guard let png = encodePNG(opaque) else { return nil }
        return Output(png: png, pixelSize: PixelSize(opaque.width, opaque.height), hasAlpha: pngHasAlpha(png))
    }

    /// Flattens onto white and returns a 24-bit RGB image with no alpha channel.
    /// A `noneSkipLast` context image is still written as RGBA by ImageIO, so the
    /// skipped byte is dropped by repacking the pixels.
    private static func flatten(_ image: CGImage) -> CGImage? {
        let width = image.width
        let height = image.height
        guard let context = CGContext(
            data: nil, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return nil }
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let source = context.data?.assumingMemoryBound(to: UInt8.self) else { return nil }
        let sourceStride = context.bytesPerRow
        var rgb = Data(count: width * height * 3)
        rgb.withUnsafeMutableBytes { destination in
            guard let out = destination.bindMemory(to: UInt8.self).baseAddress else { return }
            for y in 0..<height {
                var src = source + y * sourceStride
                var dst = out + y * width * 3
                for _ in 0..<width {
                    dst[0] = src[0]
                    dst[1] = src[1]
                    dst[2] = src[2]
                    src += 4
                    dst += 3
                }
            }
        }
        guard let provider = CGDataProvider(data: rgb as CFData) else { return nil }
        return CGImage(
            width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 24,
            bytesPerRow: width * 3, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    private static func encodePNG(_ image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }

    /// Reads the color type from the PNG IHDR chunk (byte 25): 4 = gray+alpha, 6 = RGBA.
    /// Unreadable data counts as alpha so a broken file is never reported as valid.
    private static func pngHasAlpha(_ png: Data) -> Bool {
        let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        guard png.count > 25, Array(png.prefix(8)) == signature else { return true }
        let colorType = png[png.startIndex + 25]
        return colorType == 4 || colorType == 6
    }
}
