import SwiftUI
import AnattiPro

/// The ONLY place that touches the AnattiPro API surface. If the Paywall agent's
/// API differs, adjust this file (`.paywallSheet(isPresented:)` and `.requiresPro` come from AnattiPro/ProGate.swift).
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

    static func restorePurchases() async {
        await SubscriptionManager.shared.restore()
    }
}
