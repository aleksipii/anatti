import SwiftUI
import AnattiCore

/// The finished screenshot, laid out at exact pixel size (1 point = 1 pixel).
/// The editor scales it down for preview; `ScreenshotRenderer` renders it at scale 1.
struct ScreenshotCanvas: View {
    let size: PixelSize
    let placement: TextPlacement
    let title: String
    let subtitle: String
    let topHex: String
    let bottomHex: String
    let image: UIImage?

    private var layout: ScreenshotLayout { ScreenshotLayout(canvas: size, placement: placement) }

    private var prefersLightText: Bool {
        let top = HexColor.parse(topHex) ?? RGB(r: 0, g: 0, b: 0)
        let bottom = HexColor.parse(bottomHex) ?? RGB(r: 0, g: 0, b: 0)
        let mid = RGB(r: (top.r + bottom.r) / 2, g: (top.g + bottom.g) / 2, b: (top.b + bottom.b) / 2)
        return mid.prefersLightText
    }

    var body: some View {
        let layout = layout
        let textColor: Color = prefersLightText ? .white : .black
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(hex: topHex), Color(hex: bottomHex)],
                           startPoint: .top, endPoint: .bottom)

            VStack(alignment: layout.isSideBySide ? .leading : .center, spacing: layout.titleFontSize * 0.35) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: layout.titleFontSize, weight: .bold, design: .rounded))
                        .lineLimit(3)
                }
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: layout.subtitleFontSize, weight: .medium, design: .rounded))
                        .opacity(0.85)
                        .lineLimit(3)
                }
            }
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(layout.isSideBySide ? .leading : .center)
            .foregroundStyle(textColor)
            .frame(width: layout.textFrame.width, height: layout.textFrame.height,
                   alignment: layout.isSideBySide ? .leading : (placement == .top ? .top : .bottom))
            .offset(x: layout.textFrame.minX, y: layout.textFrame.minY)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: layout.cornerRadius * 0.6, y: layout.cornerRadius * 0.3)
                    .frame(width: layout.imageFrame.width, height: layout.imageFrame.height)
                    .offset(x: layout.imageFrame.minX, y: layout.imageFrame.minY)
            }
        }
        .frame(width: CGFloat(size.width), height: CGFloat(size.height), alignment: .topLeading)
        .clipped()
    }
}
