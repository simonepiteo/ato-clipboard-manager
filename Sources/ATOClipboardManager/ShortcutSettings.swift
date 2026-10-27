import AppKit
import Carbon.HIToolbox
import Foundation

enum ShortcutAction: String, Codable, CaseIterable, Identifiable {
    case togglePopover
    case showHistory
    case showFavorites
    case toggleSelectedItemPin
    case enterSelectionMode
    case zoomSelectedItem
    case openSettings
    case quit
    case selectItem1, selectItem2, selectItem3, selectItem4, selectItem5
    case selectItem6, selectItem7, selectItem8, selectItem9

    var id: String { rawValue }

    var itemIndex: Int? {
        switch self {
        case .selectItem1: 0
        case .selectItem2: 1
        case .selectItem3: 2
        case .selectItem4: 3
        case .selectItem5: 4
        case .selectItem6: 5
        case .selectItem7: 6
        case .selectItem8: 7
        case .selectItem9: 8
        default: nil
        }
    }

    static func selectItem(at index: Int) -> ShortcutAction? {
        allCases.first { $0.itemIndex == index }
    }
}

enum ShortcutModifier: String, Codable, CaseIterable, Hashable {
    case control, option, shift, command

    var symbol: String {
        switch self {
        case .control: "⌃"
        case .option: "⌥"
        case .shift: "⇧"
        case .command: "⌘"
        }
    }
}

struct AppShortcut: Codable, Equatable, Hashable {
    let keyCode: UInt16
    let key: String
    let modifiers: Set<ShortcutModifier>

    var displayString: String {
        ShortcutModifier.allCases
            .filter(modifiers.contains)
            .map(\.symbol)
            .joined() + key
    }

    var carbonModifiers: UInt32 {
        modifiers.reduce(into: UInt32(0)) { result, modifier in
            switch modifier {
            case .command: result |= UInt32(cmdKey)
            case .option: result |= UInt32(optionKey)
            case .control: result |= UInt32(controlKey)
            case .shift: result |= UInt32(shiftKey)
            }
        }
    }

    init(keyCode: UInt16, key: String, modifiers: Set<ShortcutModifier>) {
        self.keyCode = keyCode
        self.key = key
        self.modifiers = modifiers
    }

    init(event: NSEvent) {
        let modifiers = Self.modifiers(from: event.modifierFlags)
        keyCode = event.keyCode
        key = Self.keyLabel(for: event)
        self.modifiers = modifiers
    }

    func matches(_ event: NSEvent) -> Bool {
        keyCode == event.keyCode && modifiers == Self.modifiers(from: event.modifierFlags)
    }

    private static func modifiers(from flags: NSEvent.ModifierFlags) -> Set<ShortcutModifier> {
        var result = Set<ShortcutModifier>()
        let flags = flags.intersection([.command, .option, .control, .shift])
        if flags.contains(.control) { result.insert(.control) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.shift) { result.insert(.shift) }
        if flags.contains(.command) { result.insert(.command) }
        return result
    }

    private static func keyLabel(for event: NSEvent) -> String {
        let specialKeys: [UInt16: String] = [
            UInt16(kVK_Return): "↩", UInt16(kVK_Tab): "⇥", UInt16(kVK_Space): "Space",
            UInt16(kVK_Delete): "⌫", UInt16(kVK_ForwardDelete): "⌦",
            UInt16(kVK_LeftArrow): "←", UInt16(kVK_RightArrow): "→",
            UInt16(kVK_UpArrow): "↑", UInt16(kVK_DownArrow): "↓",
            UInt16(kVK_Home): "↖", UInt16(kVK_End): "↘",
            UInt16(kVK_PageUp): "⇞", UInt16(kVK_PageDown): "⇟",
            UInt16(kVK_Escape): "⎋",
            UInt16(kVK_F1): "F1", UInt16(kVK_F2): "F2", UInt16(kVK_F3): "F3",
            UInt16(kVK_F4): "F4", UInt16(kVK_F5): "F5", UInt16(kVK_F6): "F6",
            UInt16(kVK_F7): "F7", UInt16(kVK_F8): "F8", UInt16(kVK_F9): "F9",
            UInt16(kVK_F10): "F10", UInt16(kVK_F11): "F11", UInt16(kVK_F12): "F12"
        ]
        if let label = specialKeys[event.keyCode] { return label }
        return event.charactersIgnoringModifiers?.uppercased() ?? "?"
    }
}

enum ShortcutSettingsIssue: Equatable {
    case modifierRequired
    case duplicate(ShortcutAction)
    case persistence(String)
}

struct ShortcutPersistence {
    enum PersistenceError: LocalizedError {
        case invalidDocument

        var errorDescription: String? {
            "The shortcut file contains duplicate or invalid assignments."
        }
    }

    private struct Document: Codable {
        let version: Int
        let shortcuts: [Entry]
    }

    private struct Entry: Codable {
        let action: ShortcutAction
        let shortcut: AppShortcut
    }

    let fileURL: URL
    private let fileManager: FileManager

    init(
        fileURL: URL = URL(fileURLWithPath: NSString(string: "~/.ato/shortcut.json").expandingTildeInPath),
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL.standardizedFileURL
        self.fileManager = fileManager
    }

    func load() throws -> [ShortcutAction: AppShortcut]? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let document = try JSONDecoder().decode(Document.self, from: Data(contentsOf: fileURL))
        var result = [ShortcutAction: AppShortcut]()
        for entry in document.shortcuts {
            guard result[entry.action] == nil, !entry.shortcut.modifiers.isEmpty else {
                throw PersistenceError.invalidDocument
            }
            result[entry.action] = entry.shortcut
        }
        guard Set(result.values).count == result.count else {
            throw PersistenceError.invalidDocument
        }
        return result
    }

    func save(_ shortcuts: [ShortcutAction: AppShortcut]) throws {
        let directory = fileURL.deletingLastPathComponent()
        let directoryExists = fileManager.fileExists(atPath: directory.path)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        if !directoryExists {
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        }

        let entries = ShortcutAction.allCases.compactMap { action in
            shortcuts[action].map { Entry(action: action, shortcut: $0) }
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(Document(version: 1, shortcuts: entries)).write(to: fileURL, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}

@MainActor
final class ShortcutSettings: ObservableObject {
    static let defaultShortcuts: [ShortcutAction: AppShortcut] = [
        .togglePopover: AppShortcut(keyCode: UInt16(kVK_ANSI_V), key: "V", modifiers: [.command, .shift]),
        .showHistory: AppShortcut(keyCode: UInt16(kVK_ANSI_H), key: "H", modifiers: [.command, .shift]),
        .showFavorites: AppShortcut(keyCode: UInt16(kVK_ANSI_F), key: "F", modifiers: [.command, .shift]),
        .toggleSelectedItemPin: AppShortcut(keyCode: UInt16(kVK_ANSI_P), key: "P", modifiers: [.command]),
        .enterSelectionMode: AppShortcut(keyCode: UInt16(kVK_ANSI_M), key: "M", modifiers: [.command, .shift]),
        .zoomSelectedItem: AppShortcut(keyCode: UInt16(kVK_ANSI_Z), key: "Z", modifiers: [.command, .option]),
        .openSettings: AppShortcut(keyCode: UInt16(kVK_ANSI_S), key: "S", modifiers: [.command, .option]),
        .quit: AppShortcut(keyCode: UInt16(kVK_ANSI_Q), key: "Q", modifiers: [.command]),
        .selectItem1: AppShortcut(keyCode: UInt16(kVK_ANSI_1), key: "1", modifiers: [.command]),
        .selectItem2: AppShortcut(keyCode: UInt16(kVK_ANSI_2), key: "2", modifiers: [.command]),
        .selectItem3: AppShortcut(keyCode: UInt16(kVK_ANSI_3), key: "3", modifiers: [.command]),
        .selectItem4: AppShortcut(keyCode: UInt16(kVK_ANSI_4), key: "4", modifiers: [.command]),
        .selectItem5: AppShortcut(keyCode: UInt16(kVK_ANSI_5), key: "5", modifiers: [.command]),
        .selectItem6: AppShortcut(keyCode: UInt16(kVK_ANSI_6), key: "6", modifiers: [.command]),
        .selectItem7: AppShortcut(keyCode: UInt16(kVK_ANSI_7), key: "7", modifiers: [.command]),
        .selectItem8: AppShortcut(keyCode: UInt16(kVK_ANSI_8), key: "8", modifiers: [.command]),
        .selectItem9: AppShortcut(keyCode: UInt16(kVK_ANSI_9), key: "9", modifiers: [.command])
    ]

    @Published private(set) var shortcuts: [ShortcutAction: AppShortcut]
    @Published var issue: ShortcutSettingsIssue?

    private let persistence: ShortcutPersistence

    init(persistence: ShortcutPersistence = ShortcutPersistence()) {
        self.persistence = persistence
        do {
            let loaded = try persistence.load() ?? [:]
            var merged = Self.defaultShortcuts.merging(loaded) { _, saved in saved }
            if loaded[.zoomSelectedItem] == nil,
               let standardZoom = Self.defaultShortcuts[.zoomSelectedItem] {
                let occupied = Set(merged.filter { $0.key != .zoomSelectedItem }.map(\.value))
                if occupied.contains(standardZoom) {
                    // Adding the new command must not reset a user's existing bindings.
                    let preferred: [Set<ShortcutModifier>] = [
                        [.command, .option, .shift], [.command, .option, .control],
                        [.command, .option, .control, .shift]
                    ]
                    let modifiers = ShortcutModifier.allCases
                    let remaining = (1..<(1 << modifiers.count)).map { mask in
                        Set(modifiers.enumerated().compactMap { index, modifier in
                            mask & (1 << index) == 0 ? nil : modifier
                        })
                    }
                    guard let replacement = (preferred + remaining).map({
                        AppShortcut(keyCode: standardZoom.keyCode, key: standardZoom.key, modifiers: $0)
                    }).first(where: { !occupied.contains($0) }) else {
                        throw ShortcutPersistence.PersistenceError.invalidDocument
                    }
                    merged[.zoomSelectedItem] = replacement
                }
            }
            guard Set(merged.values).count == merged.count else {
                throw ShortcutPersistence.PersistenceError.invalidDocument
            }
            shortcuts = merged
            try persistence.save(shortcuts)
        } catch {
            shortcuts = Self.defaultShortcuts
            issue = .persistence(error.localizedDescription)
        }
    }

    func shortcut(for action: ShortcutAction) -> AppShortcut {
        shortcuts[action] ?? Self.defaultShortcuts[action]!
    }

    func action(matching event: NSEvent) -> ShortcutAction? {
        ShortcutAction.allCases.first { action in shortcut(for: action).matches(event) }
    }

    func isCustomized(_ action: ShortcutAction) -> Bool {
        shortcut(for: action) != Self.defaultShortcuts[action]
    }

    func set(_ shortcut: AppShortcut, for action: ShortcutAction) {
        guard !shortcut.modifiers.isEmpty else {
            issue = .modifierRequired
            return
        }
        if let duplicate = shortcuts.first(where: { $0.key != action && $0.value == shortcut })?.key {
            issue = .duplicate(duplicate)
            return
        }

        let previous = shortcuts
        shortcuts[action] = shortcut
        do {
            try persistence.save(shortcuts)
            issue = nil
        } catch {
            shortcuts = previous
            issue = .persistence(error.localizedDescription)
        }
    }

    func reset() {
        let previous = shortcuts
        shortcuts = Self.defaultShortcuts
        do {
            try persistence.save(shortcuts)
            issue = nil
        } catch {
            shortcuts = previous
            issue = .persistence(error.localizedDescription)
        }
    }

    func reset(_ action: ShortcutAction) {
        guard let defaultShortcut = Self.defaultShortcuts[action] else { return }
        set(defaultShortcut, for: action)
    }
}
