import Foundation

struct HistoryPersistence {
    private struct Document: Codable {
        let version: Int
        let items: [ClipboardItem]
    }

    enum PersistenceError: LocalizedError {
        case emptyPath

        var errorDescription: String? {
            "The history file path cannot be empty."
        }
    }

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func resolvedURL(for path: String) throws -> URL {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { throw PersistenceError.emptyPath }
        let expandedPath = NSString(string: trimmedPath).expandingTildeInPath
        return URL(fileURLWithPath: expandedPath).standardizedFileURL
    }

    func load(from path: String) throws -> [ClipboardItem] {
        let url = try resolvedURL(for: path)
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Document.self, from: data).items
    }

    func save(_ items: [ClipboardItem], to path: String) throws {
        let url = try resolvedURL(for: path)
        let directory = url.deletingLastPathComponent()
        let directoryAlreadyExists = fileManager.fileExists(atPath: directory.path)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        if !directoryAlreadyExists {
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(Document(version: 1, items: items))
        try data.write(to: url, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    func delete(at path: String) throws {
        let url = try resolvedURL(for: path)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    func exists(at path: String) -> Bool {
        guard let url = try? resolvedURL(for: path) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }
}
