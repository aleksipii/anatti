import SwiftUI
import AnattiPro

struct ExportView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if subscription.isPro {
                    // Export flow is added in a later phase.
                    ContentUnavailableView {
                        Label("tab.export", systemImage: "square.and.arrow.up")
                    }
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
