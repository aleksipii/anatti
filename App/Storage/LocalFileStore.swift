import Foundation

/// Stores user files (source screenshots, videos, icons) under
/// Application Support/Anatti/Files. Nothing is sent to iCloud or any server.
///
/// Backup choice: `isExcludedFromBackup` is set to `false`, so files are part of the
/// user's own encrypted device backup (iCloud Backup / computer backup). This is not
/// app-level iCloud sync; it just lets users restore their projects with a new phone.
/// Flip `excludeFromBackup` if the files should be treated as re-creatable cache.
struct LocalFileStore: Sendable {
    let directory: URL
    let excludeFromBackup: Bool

    static let shared = LocalFileStore()

    init(directory: URL? = nil, excludeFromBackup: Bool = false) {
        if let directory {
            self.directory = directory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.directory = base.appendingPathComponent("Anatti/Files", isDirectory: true)
        }
        self.excludeFromBackup = excludeFromBackup
    }

    func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename, isDirectory: false)
    }

    func exists(_ filename: String) -> Bool {
        FileManager.default.fileExists(atPath: url(for: filename).path)
    }

    private func prepareDirectory() throws {
        var dir = directory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = excludeFromBackup
        try dir.setResourceValues(values)
    }

    /// Saves data and returns the stored file name. Pass `filename` to choose the name.
    @discardableResult
    func save(_ data: Data, filename: String? = nil, fileExtension: String = "dat") throws -> String {
        try prepareDirectory()
        let name = filename ?? "\(UUID().uuidString).\(fileExtension)"
        try data.write(to: url(for: name), options: [.atomic])
        return name
    }

    /// Copies an existing file (e.g. a picked video) into the store.
    @discardableResult
    func importFile(at source: URL, fileExtension: String? = nil) throws -> String {
        try prepareDirectory()
        let ext = fileExtension ?? source.pathExtension
        let name = ext.isEmpty ? UUID().uuidString : "\(UUID().uuidString).\(ext)"
        try FileManager.default.copyItem(at: source, to: url(for: name))
        return name
    }

    func load(_ filename: String) throws -> Data {
        try Data(contentsOf: url(for: filename))
    }

    func delete(_ filename: String) throws {
        let target = url(for: filename)
        if FileManager.default.fileExists(atPath: target.path) {
            try FileManager.default.removeItem(at: target)
        }
    }
}
