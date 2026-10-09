import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @Query private var slides: [Slide]

    init(project: Project) {
        self.project = project
        let id = project.id
        _slides = Query(filter: #Predicate<Slide> { $0.projectID == id }, sort: \Slide.order)
    }

    var body: some View {
        List {
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
            }
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

    private func colorBinding(_ keyPath: ReferenceWritableKeyPath<Project, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: project[keyPath: keyPath]) },
            set: { project[keyPath: keyPath] = $0.hexString }
        )
    }
}
