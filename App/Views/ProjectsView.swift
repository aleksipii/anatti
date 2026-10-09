import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    ContentUnavailableView {
                        Label("projects.empty.title", systemImage: "square.stack")
                    } description: {
                        Text("projects.empty.message")
                    }
                } else {
                    List {
                        ForEach(projects) { project in
                            NavigationLink {
                                ProjectDetailView(project: project)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(project.name).font(.headline)
                                    Text(String(format: String(localized: "project.created"), project.createdAt.formatted(date: .abbreviated, time: .omitted)))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("tab.projects")
            .overlay(alignment: .bottomTrailing) {
                newProjectButton
                    .padding()
            }
            .sheet(isPresented: $showingCreate) {
                NewProjectSheet { name in
                    modelContext.insert(Project(name: name))
                }
            }
        }
    }

    private var newProjectButton: some View {
        GlassEffectContainer {
            Button {
                showingCreate = true
            } label: {
                Label("projects.new", systemImage: "plus")
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.deleteProject(projects[index])
        }
    }
}

private struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    let onCreate: (String) -> Void

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                TextField("project.name.placeholder", text: $name)
                    .submitLabel(.done)
            }
            .navigationTitle("projects.new")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("project.create") {
                        onCreate(trimmed)
                        dismiss()
                    }
                    .disabled(trimmed.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
