import SwiftUI
import SwiftData
import AnattiCore
import AnattiPro

struct ExportView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if subscription.isPro {
                    ExportFlowView()
                } else {
                    ContentUnavailableView {
                        Label("export.locked", systemImage: "lock.fill")
                    } actions: {
                        GlassEffectContainer {
                            Button("export.unlock") { showingPaywall = true }
                                .buttonStyle(.glassProminent)
                                .controlSize(.large)
                        }
                    }
                }
            }
            .navigationTitle("tab.export")
            .paywallSheet(isPresented: $showingPaywall)
        }
    }
}

/// Pro only: pick a project and sizes, render, then save or share the folder.
private struct ExportFlowView: View {
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var selectedID: UUID?

    var body: some View {
        if projects.isEmpty {
            ContentUnavailableView {
                Label("projects.empty.title", systemImage: "square.stack")
            } description: {
                Text("projects.empty.message")
            }
        } else {
            let project = projects.first { $0.id == selectedID } ?? projects[0]
            VStack(spacing: 0) {
                if projects.count > 1 {
                    Picker("export.project", selection: Binding(
                        get: { project.id }, set: { selectedID = $0 })) {
                        ForEach(projects) { Text($0.name).tag($0.id) }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                }
                ExportOptionsView(project: project)
                    .id(project.id)
            }
        }
    }
}

private struct ExportOptionsView: View {
    let project: Project
    @Query private var slides: [Slide]
    @Query private var assets: [SourceAsset]
    @State private var selectedVideoSizes: Set<PixelSize> = []
    @State private var selectedPlay: Set<PlayAsset> = []
    @State private var selected: Set<PixelSize> = Set(ScreenshotTarget.all.filter(\.isRequired).map(\.size))
    @State private var progress = 0.0
    @State private var isExporting = false
    @State private var result: ExportService.Result?
    @State private var failed = false
    @State private var showingSave = false
    @State private var showingShare = false

    init(project: Project) {
        self.project = project
        let id = project.id
        _slides = Query(filter: #Predicate<Slide> { $0.projectID == id }, sort: \Slide.order)
        _assets = Query(filter: #Predicate<SourceAsset> { $0.projectID == id }, sort: \SourceAsset.createdAt)
    }

    private var targets: [ScreenshotTarget] { ScreenshotTarget.all.filter { selected.contains($0.size) } }

    private var videos: [SourceAsset] { assets.filter { $0.kind == .video } }
    private var videoTargets: [VideoTarget] { VideoTarget.all.filter { selectedVideoSizes.contains($0.size) } }

    private var warnings: [ExportWarning] {
        slides.isEmpty ? [] : ExportPlanner.warnings(slideCount: slides.count, specs: targets.flatMap(\.specs))
    }

    private var videoWarnings: [ExportWarning] {
        videos.isEmpty ? [] : ExportPlanner.warnings(slideCount: videos.count, specs: videoTargets.flatMap(\.specs))
    }

    private var playAssets: [PlayAsset] { PlayAsset.allCases.filter { selectedPlay.contains($0) } }

    private var hasIcon: Bool { project.appIconFilename != nil }

    private var hasWork: Bool {
        (!slides.isEmpty && !targets.isEmpty) || (!videos.isEmpty && !videoTargets.isEmpty) || !playAssets.isEmpty
    }

    var body: some View {
        List {
            if slides.isEmpty && videos.isEmpty {
                Section { Text("export.nocontent").foregroundStyle(.secondary) }
            }

            Section("export.sizes") {
                ForEach(ScreenshotTarget.all) { target in
                    Toggle(target.isRequired ? "★ \(target.size.label)" : target.size.label,
                           isOn: Binding(
                            get: { selected.contains(target.size) },
                            set: { on in
                                if on { selected.insert(target.size) } else { selected.remove(target.size) }
                                result = nil
                            }))
                }
            }

            Section {
                ForEach(PlayAsset.allCases) { asset in
                    Toggle(isOn: Binding(
                        get: { selectedPlay.contains(asset) },
                        set: { on in
                            if on { selectedPlay.insert(asset) } else { selectedPlay.remove(asset) }
                            result = nil
                        })) {
                        VStack(alignment: .leading) {
                            Text(asset.titleKey)
                            Text(asset.size.label).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .disabled(asset.needsIcon && !hasIcon)
                }
                if !hasIcon {
                    Text("export.play.noicon").font(.caption).foregroundStyle(.secondary)
                }
            } header: {
                Text("export.play")
            }

            if !videos.isEmpty {
                Section("export.videos") {
                    ForEach(VideoTarget.all) { target in
                        Toggle(target.size.label, isOn: Binding(
                            get: { selectedVideoSizes.contains(target.size) },
                            set: { on in
                                if on { selectedVideoSizes.insert(target.size) } else { selectedVideoSizes.remove(target.size) }
                                result = nil
                            }))
                    }
                }
            }

            if !warnings.isEmpty || !videoWarnings.isEmpty {
                Section {
                    ForEach(warnings, id: \.self) { warning in
                        Label(text(for: warning), systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    ForEach(videoWarnings, id: \.self) { warning in
                        if case .tooMany(let max, let have) = warning {
                            Label(String(format: String(localized: "export.warn.videos"), max, have),
                                  systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            Section {
                Button(action: startExport) {
                    Label("export.start", systemImage: "square.and.arrow.up")
                }
                .disabled(!hasWork || isExporting)

                if isExporting {
                    ProgressView(value: progress)
                }
                if failed {
                    Label("editor.check.failed", systemImage: "xmark.octagon.fill").foregroundStyle(.red)
                }
                if let result {
                    Label(String(format: String(localized: "export.done"), result.written),
                          systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    if result.skipped > 0 {
                        Label(String(format: String(localized: "export.skipped"), result.skipped),
                              systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    if result.written > 0 {
                        Button("export.save", systemImage: "folder") { showingSave = true }
                        Button("export.share", systemImage: "square.and.arrow.up") { showingShare = true }
                    }
                }
            }
        }
        .fileExporter(
            isPresented: $showingSave,
            document: result.map { FolderDocument(url: $0.folder) },
            contentType: .folder,
            defaultFilename: project.name
        ) { _ in }
        .sheet(isPresented: $showingShare) {
            if let result { ActivityView(items: [result.folder]) }
        }
    }

    private func text(for warning: ExportWarning) -> String {
        switch warning {
        case .tooMany(let max, let have):
            String(format: String(localized: "export.warn.many"), max, have)
        case .tooFew(let min, let have):
            String(format: String(localized: "export.warn.few"), min, have)
        }
    }

    private func startExport() {
        let previous = result?.folder
        isExporting = true
        failed = false
        result = nil
        progress = 0
        Task {
            do {
                result = try await ExportService.export(
                    project: project, slides: slides, targets: slides.isEmpty ? [] : targets,
                    videos: videos, videoTargets: videoTargets, playAssets: playAssets,
                    progress: { progress = $0 })
            } catch {
                failed = true
            }
            if let previous { try? FileManager.default.removeItem(at: previous) }
            isExporting = false
        }
    }
}
