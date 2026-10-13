import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let language = "language"
        static let displayMode = "displayMode"
        static let maxHistoryItems = "maxHistoryItems"
        static let automaticPaste = "automaticPaste"
        static let automaticPasteShortcut = "automaticPasteShortcut"
    }

    static let defaultMaxHistoryItems = 20
    private let defaults: UserDefaults

    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: Key.language) } }
    @Published var displayMode: DisplayMode { didSet { defaults.set(displayMode.rawValue, forKey: Key.displayMode) } }
    @Published var maxHistoryItems: Int {
        didSet {
            let validValue = Self.clampHistoryLimit(maxHistoryItems)
            if maxHistoryItems != validValue {
                maxHistoryItems = validValue
                return
            }
            defaults.set(validValue, forKey: Key.maxHistoryItems)
        }
    }
    @Published var automaticPaste: Bool { didSet { defaults.set(automaticPaste, forKey: Key.automaticPaste) } }
    @Published var automaticPasteShortcut: Bool { didSet { defaults.set(automaticPasteShortcut, forKey: Key.automaticPasteShortcut) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = AppLanguage(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .english
        displayMode = DisplayMode(rawValue: defaults.string(forKey: Key.displayMode) ?? "") ?? .grid
        let savedLimit = defaults.object(forKey: Key.maxHistoryItems) as? Int
        maxHistoryItems = Self.clampHistoryLimit(savedLimit ?? Self.defaultMaxHistoryItems)
        automaticPaste = defaults.bool(forKey: Key.automaticPaste)
        automaticPasteShortcut = defaults.object(forKey: Key.automaticPasteShortcut) as? Bool ?? true
    }

    nonisolated static func clampHistoryLimit(_ value: Int) -> Int {
        min(max(value, 1), 100)
    }

    func reset() {
        language = .english
        displayMode = .grid
        maxHistoryItems = Self.defaultMaxHistoryItems
        automaticPaste = false
        automaticPasteShortcut = true
    }
}
