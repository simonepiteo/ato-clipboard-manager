import AppKit
import Foundation

enum ClipboardContent: Hashable, Codable {
    case text(String)
    case image(Data)

    private enum CodingKeys: String, CodingKey {
        case type, text, data
    }

    private enum ContentType: String, Codable {
        case text, image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(ContentType.self, forKey: .type) {
        case .text:
            self = .text(try container.decode(String.self, forKey: .text))
        case .image:
            self = .image(try container.decode(Data.self, forKey: .data))
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
        guard case let .text(value) = content else { return "" }
        return value
    }
}

enum DisplayMode: String, CaseIterable, Identifiable {
    case grid
    case list

    var id: String { rawValue }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case italian = "it"

    var id: String { rawValue }
    var displayName: String { self == .english ? "English" : "Italiano" }
}
