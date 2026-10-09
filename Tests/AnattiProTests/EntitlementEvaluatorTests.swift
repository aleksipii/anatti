import Foundation
import Testing
@testable import AnattiPro

struct EntitlementEvaluatorTests {
    let evaluator = EntitlementEvaluator()
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let id = ProProduct.monthlyID

    @Test func noRecordsIsNotPro() {
        #expect(!evaluator.isPro(records: [], now: now))
    }

    @Test func activeSubscriptionIsPro() {
        let r = EntitlementRecord(productID: id, expirationDate: now.addingTimeInterval(86_400))
        #expect(evaluator.isPro(records: [r], now: now))
    }

    @Test func noExpirationIsPro() {
        let r = EntitlementRecord(productID: id, expirationDate: nil)
        #expect(evaluator.isPro(records: [r], now: now))
    }

    @Test func expiredIsNotPro() {
        let r = EntitlementRecord(productID: id, expirationDate: now.addingTimeInterval(-1))
        #expect(!evaluator.isPro(records: [r], now: now))
    }

    @Test func expiringExactlyNowIsNotPro() {
        let r = EntitlementRecord(productID: id, expirationDate: now)
        #expect(!evaluator.isPro(records: [r], now: now))
    }

    @Test func revokedIsNotPro() {
        let r = EntitlementRecord(productID: id,
                                  expirationDate: now.addingTimeInterval(86_400),
                                  revocationDate: now.addingTimeInterval(-60))
        #expect(!evaluator.isPro(records: [r], now: now))
    }

    @Test func wrongProductIsNotPro() {
        let r = EntitlementRecord(productID: "fi.other.product", expirationDate: now.addingTimeInterval(86_400))
        #expect(!evaluator.isPro(records: [r], now: now))
    }

    @Test func expiredPlusActiveIsPro() {
        let old = EntitlementRecord(productID: id, expirationDate: now.addingTimeInterval(-86_400))
        let new = EntitlementRecord(productID: id, expirationDate: now.addingTimeInterval(86_400))
        #expect(evaluator.isPro(records: [old, new], now: now))
    }

    @Test func revokedPlusActiveDuplicateIsPro() {
        let revoked = EntitlementRecord(productID: id, expirationDate: now.addingTimeInterval(86_400),
                                        revocationDate: now.addingTimeInterval(-1))
        let active = EntitlementRecord(productID: id, expirationDate: now.addingTimeInterval(3_600))
        #expect(evaluator.isPro(records: [revoked, active, active], now: now))
    }

    @Test func customProductSetIsRespected() {
        let custom = EntitlementEvaluator(proProductIDs: ["a", "b"])
        let r = EntitlementRecord(productID: "b", expirationDate: now.addingTimeInterval(10))
        #expect(custom.isPro(records: [r], now: now))
        #expect(!custom.isPro(records: [EntitlementRecord(productID: id, expirationDate: nil)], now: now))
    }
}
