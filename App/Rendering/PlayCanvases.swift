import SwiftUI
import AnattiCore

/// Play app icon: the project's icon filling the square. Google applies its own corner mask,
/// so no rounding here. Transparent areas sit on the project color.
struct IconCanvas: View {
    let size: PixelSize
    let backgroundHex: String
    let image: UIImage?

    var body: some View {
        ZStack {
            Color(hex: backgroundHex)
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            }
        }
        .frame(width: CGFloat(size.width), height: CGFloat(size.height))
        .clipped()
    }
}

/// Feature graphic and TV banner: icon, name and tagline on the project gradient, inside the safe area.
struct BrandCanvas: View {
    let size: PixelSize
    let title: String
    let tagline: String
    let topHex: String
    let bottomHex: String
    let icon: UIImage?

    var body: some View {
        let layout = BrandLayout(canvas: size, hasIcon: icon != nil)
        let textColor: Color = HexColor.prefersLightText(topHex: topHex, bottomHex: bottomHex) ? .white : .black
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(hex: topHex), Color(hex: bottomHex)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            if let icon, let frame = layout.iconFrame {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: frame.width, height: frame.height)
                    .clipShape(RoundedRectangle(cornerRadius: layout.iconCornerRadius, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: frame.width * 0.06, y: frame.width * 0.03)
                    .offset(x: frame.minX, y: frame.minY)
            }

            VStack(alignment: .leading, spacing: layout.titleFontSize * 0.25) {
                Text(title)
                    .font(.system(size: layout.titleFontSize, weight: .bold, design: .rounded))
                    .lineLimit(2)
                if !tagline.isEmpty {
                    Text(tagline)
                        .font(.system(size: layout.taglineFontSize, weight: .medium, design: .rounded))
                        .opacity(0.85)
                        .lineLimit(3)
                }
            }
            .minimumScaleFactor(0.5)
            .foregroundStyle(textColor)
            .frame(width: layout.textFrame.width, height: layout.textFrame.height, alignment: .leading)
            .offset(x: layout.textFrame.minX, y: layout.textFrame.minY)
        }
        .frame(width: CGFloat(size.width), height: CGFloat(size.height), alignment: .topLeading)
        .clipped()
    }
}
