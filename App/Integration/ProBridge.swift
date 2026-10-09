import SwiftUI
import StoreKit
import AnattiPro

/// The ONLY place that touches the AnattiPro API surface. If the Paywall agent's
/// API differs, adjust this file (and `PaywallView` usage in `ProSheets`).
///
/// Assumed API:
///   `@MainActor @Observable final class SubscriptionManager { static let shared; var isPro: Bool; func start() async }`
///   `PaywallView` (SwiftUI view with an `init()`)
@MainActor
enum ProBridge {
    static var manager: SubscriptionManager { SubscriptionManager.shared }

    static func start() async {
        await SubscriptionManager.shared.start()
    }

    /// Restore purchases through StoreKit; SubscriptionManager picks up
    /// the resulting entitlements via Transaction.updates / currentEntitlements.
    static func restorePurchases() async {
        try? await AppStore.sync()
    }
}

extension View {
    /// Presents the paywall as a sheet.
    func paywallSheet(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            PaywallView()
        }
    }
}
