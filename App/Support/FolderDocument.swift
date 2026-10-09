import SwiftUI
import UniformTypeIdentifiers

/// Lets `fileExporter` save a whole folder to the Files app.
struct FolderDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.folder]
    let url: URL

    init(url: URL) { self.url = url }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnsupportedScheme)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url, options: .immediate)
    }
}

/// Share sheet (AirDrop, Messages, Save to Files, ...).
struct ActivityView: UIViewControllerRepresentable {
    let items: [URL]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
