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
    }

    private var targets: [ScreenshotTarget] { ScreenshotTarget.all.filter { selected.contains($0.size) } }

    private var warnings: [ExportWarning] {
        ExportPlanner.warnings(slideCount: slides.count, specs: targets.flatMap(\.specs))
    }

    var body: some View {
        List {
            if slides.isEmpty {
                Section { Text("export.noslides").foregroundStyle(.secondary) }
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

            if !slides.isEmpty && !warnings.isEmpty {
                Section {
                    ForEach(warnings, id: \.self) { warning in
                        Label(text(for: warning), systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section {
                Button(action: startExport) {
                    Label("export.start", systemImage: "square.and.arrow.up")
                }
                .disabled(slides.isEmpty || targets.isEmpty || isExporting)

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
                    project: project, slides: slides, targets: targets,
                    progress: { progress = $0 })
            } catch {
                failed = true
            }
            if let previous { try? FileManager.default.removeItem(at: previous) }
            isExporting = false
        }
    }
}
