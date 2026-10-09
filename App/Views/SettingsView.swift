import SwiftUI
import StoreKit
import AnattiPro

struct SettingsView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @State private var showingPaywall = false
    @State private var showingManage = false
    @State private var restoreMessage: LocalizedStringKey?

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.section.subscription") {
                    HStack {
                        Text("settings.pro")
                        Spacer()
                        Text(LocalizedStringKey(subscription.isPro ? "settings.pro.active" : "settings.pro.inactive"))
                            .foregroundStyle(.secondary)
                    }
                    if !subscription.isPro {
                        Button("export.unlock") { showingPaywall = true }
                    }
                    Button("settings.restore") {
                        Task {
                            await ProBridge.restorePurchases()
                            restoreMessage = subscription.isPro ? "paywall.thanks" : "settings.restore.none"
                        }
                    }
                    Button("settings.manage") { showingManage = true }
                }
                Section("settings.section.privacy") {
                    Text("settings.privacy.note")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("tab.settings")
            .paywallSheet(isPresented: $showingPaywall)
            .manageSubscriptionsSheet(isPresented: $showingManage)
            .alert("settings.restore", isPresented: Binding(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } })) {
                Button("common.done", role: .cancel) {}
            } message: {
                if let restoreMessage { Text(restoreMessage) }
            }
        }
    }
}
