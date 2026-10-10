import SwiftUI
import SwiftData
import AnattiCore
import PhotosUI
import AVFoundation

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @Query private var slides: [Slide]
    @Query private var assets: [SourceAsset]
    @State private var videoItem: PhotosPickerItem?
    @State private var importFailed = false
    @State private var iconItem: PhotosPickerItem?
    @State private var screenshotItems: [PhotosPickerItem] = []
    @State private var failedImports = 0
    @State private var iconImage: UIImage?

    init(project: Project) {
        self.project = project
        let id = project.id
        _slides = Query(filter: #Predicate<Slide> { $0.projectID == id }, sort: \Slide.order)
        _assets = Query(filter: #Predicate<SourceAsset> { $0.projectID == id }, sort: \SourceAsset.createdAt)
    }

    var body: some View {
        List {
            Section("project.brand") {
                HStack {
                    if let iconImage {
                        Image(uiImage: iconImage)
                            .resizable().scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .accessibilityHidden(true)
                    }
                    PhotosPicker(selection: $iconItem, matching: .images) {
                        Label(project.appIconFilename == nil ? "project.icon.choose" : "project.icon.replace",
                              systemImage: "app.dashed")
                    }
                }
                TextField("project.tagline", text: $project.tagline)
            }

            Section {
                ForEach(SupportedLanguage.allCases, id: \.self) { language in
                    Toggle(languageName(language.rawValue), isOn: languageBinding(language))
                        .disabled(project.baseLanguage == language.rawValue)
                }
            } header: {
                Text("project.languages")
            } footer: {
                Text("project.languages.note")
            }

            Section("project.colors") {
                ColorPicker("project.color.top", selection: colorBinding(\.primaryColorHex), supportsOpacity: false)
                ColorPicker("project.color.bottom", selection: colorBinding(\.secondaryColorHex), supportsOpacity: false)
            }

            Section("slides.title") {
                if slides.isEmpty {
                    ContentUnavailableView {
                        Label("slides.empty.title", systemImage: "photo.on.rectangle")
                    } description: {
                        Text("slides.empty.message")
                    }
                } else {
                    ForEach(slides) { slide in
                        NavigationLink {
                            SlideEditorView(slide: slide, project: project)
                        } label: {
                            if slide.title.isEmpty {
                                Text("slide.untitled").foregroundStyle(.secondary)
                            } else {
                                Text(slide.title)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { modelContext.deleteSlide(slides[index]) }
                    }
                }
                PhotosPicker(selection: $screenshotItems, matching: .images, photoLibrary: .shared()) {
                    Label("slide.import", systemImage: "photo.stack")
                }
                if failedImports > 0 {
                    Label(String(format: String(localized: "slide.import.failed"), failedImports),
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            Section("project.videos") {
                if videos.isEmpty {
                    Text("video.empty").foregroundStyle(.secondary)
                }
                ForEach(Array(videos.enumerated()), id: \.element.id) { index, asset in
                    VideoRow(number: index + 1, asset: asset)
                }
                .onDelete { offsets in
                    for index in offsets { modelContext.deleteVideo(videos[index]) }
                }
                PhotosPicker(selection: $videoItem, matching: .videos) {
                    Label("video.add", systemImage: "video.badge.plus")
                }
                if importFailed {
                    Label("video.import.failed", systemImage: "xmark.octagon.fill").foregroundStyle(.red)
                }
            }
        }
        .task(id: project.appIconFilename) {
            iconImage = project.appIconFilename
                .flatMap { try? LocalFileStore.shared.load($0) }
                .flatMap(UIImage.init(data:))
        }
        .onChange(of: screenshotItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importScreenshots(items) }
        }
        .onChange(of: iconItem) { _, item in
            guard let item else { return }
            Task { await importIcon(from: item) }
        }
        .onChange(of: videoItem) { _, item in
            guard let item else { return }
            Task { await importVideo(from: item) }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("slide.add", systemImage: "plus") {
                    modelContext.insert(Slide(projectID: project.id, order: (slides.last?.order ?? -1) + 1))
                }
            }
        }
    }

    /// The first language is the default for all texts, so it cannot be switched off.
    private func languageBinding(_ language: SupportedLanguage) -> Binding<Bool> {
        Binding(
            get: { project.languages.contains(language.rawValue) },
            set: { on in
                if on, !project.languages.contains(language.rawValue) {
                    project.languages.append(language.rawValue)
                } else if !on, project.baseLanguage != language.rawValue {
                    project.languages.removeAll { $0 == language.rawValue }
                }
            })
    }

    private func colorBinding(_ keyPath: ReferenceWritableKeyPath<Project, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: project[keyPath: keyPath]) },
            set: { project[keyPath: keyPath] = $0.hexString }
        )
    }

    /// Loads every picked image in order, then creates the slides after the existing ones.
    private func importScreenshots(_ items: [PhotosPickerItem]) async {
        defer { screenshotItems = [] }
        var images: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) { images.append(data) }
        }
        let imported = SlideImporter.importSlides(
            images, project: project, startOrder: (slides.last?.order ?? -1) + 1, context: modelContext)
        failedImports = items.count - imported
    }

    private func importIcon(from item: PhotosPickerItem) async {
        defer { iconItem = nil }
        let store = LocalFileStore.shared
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let name = try? store.save(image.pngData() ?? data, fileExtension: "png") else { return }
        if let old = project.appIconFilename { try? store.delete(old) }
        project.appIconFilename = name
    }

    private var videos: [SourceAsset] { assets.filter { $0.kind == .video } }

    private func importVideo(from item: PhotosPickerItem) async {
        defer { videoItem = nil }
        importFailed = false
        guard let picked = try? await item.loadTransferable(type: PickedVideo.self) else {
            importFailed = true
            return
        }
        modelContext.insert(SourceAsset(projectID: project.id, filename: picked.filename, kind: .video))
    }
}

/// A picked video, already copied into LocalFileStore.
private struct PickedVideo: Transferable {
    let filename: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { _ in
            throw CocoaError(.featureUnsupported)   // import only
        } importing: { received in
            PickedVideo(filename: try LocalFileStore.shared.importFile(at: received.file))
        }
    }
}

private struct VideoRow: View {
    let number: Int
    let asset: SourceAsset
    @State private var seconds: Double?

    var body: some View {
        HStack {
            Label(String(format: String(localized: "video.row"), number), systemImage: "film")
            Spacer()
            if let seconds {
                Text(Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond)))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .task {
            let info = try? await VideoConverter.inspect(LocalFileStore.shared.url(for: asset.filename))
            seconds = info?.durationSeconds
        }
    }
}
