import Foundation
import SwiftData

enum SourceAssetKind: String, Codable, Sendable {
    case image
    case video
}

@Model
final class SourceAsset {
    @Attribute(.unique) var id: UUID
    var projectID: UUID
    /// File name inside LocalFileStore.
    var filename: String
    var kind: SourceAssetKind
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectID: UUID,
        filename: String,
        kind: SourceAssetKind,
        createdAt: Date = .now
    ) {
        self.id = id
        self.projectID = projectID
        self.filename = filename
        self.kind = kind
        self.createdAt = createdAt
    }
}
