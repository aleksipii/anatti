import SwiftUI

struct RootView: View {
    var body: some View {
        // A standard TabView adopts Liquid Glass automatically on iOS 26.
        TabView {
            Tab("tab.projects", systemImage: "square.stack") {
                ProjectsView()
            }
            Tab("tab.export", systemImage: "square.and.arrow.up") {
                ExportView()
            }
            Tab("tab.settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}
