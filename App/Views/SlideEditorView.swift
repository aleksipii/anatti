import SwiftUI
import PhotosUI
import AnattiCore

struct SlideEditorView: View {
    @Bindable var slide: Slide
    let project: Project

    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var target = ScreenshotTarget.default
    @State private var checkResult: CheckResult?

    private let store = LocalFileStore.shared

    private enum CheckResult {
        case ok(sizeLabel: String, bytes: Int)
        case issues([RenderIssue])
        case failed
    }

    var body: some View {
        Form {
            Section {
                preview
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label(slide.sourceFilename == nil ? "editor.image.choose" : "editor.image.replace",
                          systemImage: "photo")
                }
            }

            Section {
                TextField("editor.headline", text: $slide.title)
                TextField("editor.caption", text: $slide.subtitle)
                Picker("editor.placement", selection: $slide.placement) {
                    Text("editor.placement.top").tag(TextPlacement.top)
                    Text("editor.placement.bottom").tag(TextPlacement.bottom)
                }
                .pickerStyle(.segmented)
            }

            Section {
                Picker("editor.size", selection: $target) {
                    ForEach(ScreenshotTarget.all) { option in
                        Text(option.isRequired ? "★ \(option.size.label)" : option.size.label).tag(option)
                    }
                }
                Button("editor.check", action: check)
                if let checkResult {
                    resultView(checkResult)
                }
            }
        }
        .navigationTitle("editor.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("common.done") { dismiss() }
            }
        }
        .task(id: slide.sourceFilename) { loadSourceImage() }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await importImage(from: item) }
        }
        .onChange(of: target) { _, _ in checkResult = nil }
    }

    private func canvas(size: PixelSize) -> ScreenshotCanvas {
        ScreenshotCanvas(size: size, placement: slide.placement, title: slide.title,
                         subtitle: slide.subtitle, topHex: project.primaryColorHex,
                         bottomHex: project.secondaryColorHex, image: sourceImage)
    }

    private var preview: some View {
        let size = target.size
        return GeometryReader { geo in
            let scale = min(geo.size.width / CGFloat(size.width), geo.size.height / CGFloat(size.height))
            // scaleEffect does not change layout size, so the full-size canvas is pinned to the
            // top-left of a frame of the scaled size; otherwise it would be centered and drawn off screen.
            canvas(size: size)
                .frame(width: CGFloat(size.width), height: CGFloat(size.height))
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: CGFloat(size.width) * scale, height: CGFloat(size.height) * scale,
                       alignment: .topLeading)
                .clipped()
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: 420)
        .padding(.vertical, 8)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func resultView(_ result: CheckResult) -> some View {
        switch result {
        case .ok(let sizeLabel, let bytes):
            let fileSize = ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
            Label(String(format: String(localized: "editor.check.ok"), sizeLabel, fileSize),
                  systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .issues(let issues):
            ForEach(Array(issues), id: \.self) { issue in
                Label(message(for: issue), systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        case .failed:
            Label("editor.check.failed", systemImage: "xmark.octagon.fill")
                .foregroundStyle(.red)
        }
    }

    private func message(for issue: RenderIssue) -> LocalizedStringKey {
        switch issue {
        case .wrongSize: "editor.check.size"
        case .hasAlpha: "editor.check.alpha"
        case .fileTooLarge: "editor.check.large"
        case .unsupportedFormat: "editor.check.format"
        }
    }

    /// Renders at the exact pixel size and validates against every spec that uses this size.
    private func check() {
        guard let output = ScreenshotRenderer.render(canvas(size: target.size)) else {
            checkResult = .failed
            return
        }
        var issues: [RenderIssue] = []
        for spec in target.specs {
            for issue in RenderValidator.validate(spec: spec, size: output.pixelSize, hasAlpha: output.hasAlpha,
                                                  format: .png, byteCount: output.data.count)
            where !issues.contains(issue) {
                issues.append(issue)
            }
        }
        checkResult = issues.isEmpty
            ? .ok(sizeLabel: output.pixelSize.label, bytes: output.data.count)
            : .issues(issues)
    }

    private func loadSourceImage() {
        guard let name = slide.sourceFilename, let data = try? store.load(name) else {
            sourceImage = nil
            return
        }
        sourceImage = UIImage(data: data)
    }

    private func importImage(from item: PhotosPickerItem) async {
        defer { pickerItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        let png = image.pngData() ?? data
        guard let name = try? store.save(png, fileExtension: "png") else { return }
        if let old = slide.sourceFilename { try? store.delete(old) }
        slide.sourceFilename = name
        checkResult = nil
    }
}
