import Foundation
import Testing
@testable import Anatti

struct LocalFileStoreTests {
    @Test func saveLoadDelete() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("anatti-test-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = LocalFileStore(directory: dir)
        let name = try store.save(Data([1, 2, 3]), fileExtension: "png")
        #expect(store.exists(name))
        #expect(try store.load(name) == Data([1, 2, 3]))
        try store.delete(name)
        #expect(!store.exists(name))
    }
}
