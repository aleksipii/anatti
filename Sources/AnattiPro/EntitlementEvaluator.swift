import Foundation

/// StoreKit-free snapshot of a verified transaction.
public struct EntitlementRecord: Sendable, Equatable, Hashable {
    public let productID: String
    public let expirationDate: Date?
    public let revocationDate: Date?

    public init(productID: String, expirationDate: Date?, revocationDate: Date? = nil) {
        self.productID = productID
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
    }
}

/// Pure entitlement decision logic. Any single active record for a Pro product grants Pro,
/// so duplicates and upgrade/renewal chains (old expired + new active) are handled.
public struct EntitlementEvaluator: Sendable {
    public let proProductIDs: Set<String>

    public init(proProductIDs: Set<String> = [ProProduct.monthlyID]) {
        self.proProductIDs = proProductIDs
    }

    public func isActive(_ record: EntitlementRecord, now: Date = Date()) -> Bool {
        guard proProductIDs.contains(record.productID) else { return false }
        guard record.revocationDate == nil else { return false }
        if let expiration = record.expirationDate { return expiration > now }
        return true
    }

    public func isPro(records: [EntitlementRecord], now: Date = Date()) -> Bool {
        records.contains { isActive($0, now: now) }
    }
}
