import Foundation
import Observation
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

public enum PurchaseState: Sendable, Equatable {
    case idle
    case purchasing
    case pending
    case success
    /// Associated value is a localization key from docs/CONTRACT.md.
    case failed(String)
}

/// On-device StoreKit 2 subscription state. No server, no analytics.
@MainActor
@Observable
public final class SubscriptionManager {
    public static let shared = SubscriptionManager()

    public private(set) var isPro: Bool
    public private(set) var product: Product?
    public private(set) var purchaseState: PurchaseState = .idle

    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    @ObservationIgnored private let evaluator = EntitlementEvaluator()
    @ObservationIgnored private static let cacheKey = "fi.anatti.pro.isPro.cache"

    private init() {
        // Offline convenience only; overwritten from StoreKit as soon as it answers.
        self.isPro = UserDefaults.standard.bool(forKey: Self.cacheKey)
    }

    /// Call once at app launch (e.g. `.task { await SubscriptionManager.shared.start() }`). Idempotent.
    public func start() async {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await result in Transaction.updates {
                    guard let self else { return }
                    await self.handle(update: result)
                }
            }
        }
        await refreshEntitlements()
        await loadProduct()
    }

    public func loadProduct() async {
        do {
            let products = try await Product.products(for: [ProProduct.monthlyID])
            product = products.first
        } catch {
            // Keep any previously loaded product; the UI shows the fallback price.
        }
    }

    public func purchase() async {
        if product == nil { await loadProduct() }
        guard let product else {
            purchaseState = .failed("paywall.error.unavailable")
            return
        }
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    purchaseState = isPro ? .success : .failed("paywall.error.generic")
                case .unverified:
                    purchaseState = .failed("paywall.error.generic")
                }
            case .pending:
                purchaseState = .pending
            case .userCancelled:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed("paywall.error.generic")
        }
    }

    public func restore() async {
        purchaseState = .purchasing
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseState = isPro ? .success : .idle
        } catch {
            await refreshEntitlements()
            purchaseState = isPro ? .success : .failed("paywall.error.generic")
        }
    }

    public func resetPurchaseState() {
        purchaseState = .idle
    }

    /// Opens the system subscription management sheet (iOS/iPadOS only; no-op elsewhere).
    public func manageSubscriptions() async {
        #if canImport(UIKit) && !os(visionOS)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else { return }
        do {
            try await AppStore.showManageSubscriptions(in: scene)
        } catch {
            purchaseState = .failed("paywall.error.generic")
        }
        #endif
    }

    // MARK: - Internals

    private func handle(update result: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = result {
            await transaction.finish()
        }
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        var records: [EntitlementRecord] = []
        for await result in Transaction.currentEntitlements {
            // Unverified transactions never grant Pro.
            guard case .verified(let t) = result else { continue }
            records.append(EntitlementRecord(
                productID: t.productID,
                expirationDate: t.expirationDate,
                revocationDate: t.revocationDate))
        }
        let value = evaluator.isPro(records: records)
        isPro = value
        UserDefaults.standard.set(value, forKey: Self.cacheKey)
    }
}
