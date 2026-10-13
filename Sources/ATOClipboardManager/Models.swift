import AppKit
import Foundation

struct ClipboardFile: Hashable, Codable, Identifiable {
    let path: String

    init(path: String) {
        self.path = URL(fileURLWithPath: path).standardizedFileURL.path
    }

    init(url: URL) {
        self.init(path: url.path)
    }

    var id: String { path }
    var url: URL { URL(fileURLWithPath: path) }
    var name: String { url.lastPathComponent }
}

enum ClipboardContent: Hashable, Codable {
    case text(String)
    case image(Data)
    case files([ClipboardFile])

    private enum CodingKeys: String, CodingKey {
        case type, text, data, files
    }

    private enum ContentType: String, Codable {
        case text, image, files
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(ContentType.self, forKey: .type) {
        case .text:
            self = .text(try container.decode(String.self, forKey: .text))
        case .image:
            self = .image(try container.decode(Data.self, forKey: .data))
        case .files:
            self = .files(try container.decode([ClipboardFile].self, forKey: .files))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .text(value):
            try container.encode(ContentType.text, forKey: .type)
            try container.encode(value, forKey: .text)
        case let .image(data):
            try container.encode(ContentType.image, forKey: .type)
            try container.encode(data, forKey: .data)
        case let .files(files):
            try container.encode(ContentType.files, forKey: .type)
            try container.encode(files, forKey: .files)
        }
    }
}

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let content: ClipboardContent

    init(id: UUID = UUID(), content: ClipboardContent) {
        self.id = id
        self.content = content
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.content == rhs.content
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
    }

    var searchableText: String {
        switch content {
        case let .text(value):
            return value
        case .image:
            return ""
        case let .files(files):
            return files.flatMap { [$0.name, $0.path] }.joined(separator: " ")
        }
    }
}

enum DisplayMode: String, CaseIterable, Identifiable {
    case grid
    case list

    var id: String { rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var appearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case italian = "it"

    var id: String { rawValue }
    var displayName: String { self == .english ? "English" : "Italiano" }
}
