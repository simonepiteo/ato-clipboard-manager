import AppKit
import Foundation

enum ClipboardContent: Equatable {
    case text(String)
    case image(Data)
}

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: ClipboardContent

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.content == rhs.content
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
