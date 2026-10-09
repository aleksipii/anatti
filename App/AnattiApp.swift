import SwiftUI
import SwiftData
import AnattiPro

@main
struct AnattiApp: App {
    /// Local-only store: no CloudKit, no App Group, data never leaves the device.
    private let container: ModelContainer = {
        let schema = Schema([Project.self, SourceAsset.self, Slide.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create local ModelContainer: \(error)")
        }
    }()

    @State private var subscription = ProBridge.manager

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(subscription)
                .task { await ProBridge.start() }
        }
        .modelContainer(container)
    }
}
