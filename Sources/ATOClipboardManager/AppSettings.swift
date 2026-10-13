import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let language = "language"
        static let displayMode = "displayMode"
        static let maxHistoryItems = "maxHistoryItems"
        static let automaticPaste = "automaticPaste"
        static let automaticPasteShortcut = "automaticPasteShortcut"
        static let launchAtLoginPromptShown = "launchAtLoginPromptShown"
        static let persistHistory = "persistHistory"
        static let historyFilePath = "historyFilePath"
        static let maxPersistedHistoryItems = "maxPersistedHistoryItems"
    }

    static let defaultMaxHistoryItems = 20
    static let defaultHistoryFilePath = "~/.ato/history.json"
    nonisolated static let maximumPersistedHistoryItems = 10_000
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
            if maxPersistedHistoryItems < validValue {
                maxPersistedHistoryItems = validValue
            }
        }
    }
    @Published var automaticPaste: Bool { didSet { defaults.set(automaticPaste, forKey: Key.automaticPaste) } }
    @Published var automaticPasteShortcut: Bool { didSet { defaults.set(automaticPasteShortcut, forKey: Key.automaticPasteShortcut) } }
    @Published var persistHistory: Bool { didSet { defaults.set(persistHistory, forKey: Key.persistHistory) } }
    @Published var historyFilePath: String { didSet { defaults.set(historyFilePath, forKey: Key.historyFilePath) } }
    @Published var maxPersistedHistoryItems: Int {
        didSet {
            let validValue = Self.clampPersistedHistoryLimit(maxPersistedHistoryItems, minimum: maxHistoryItems)
            if maxPersistedHistoryItems != validValue {
                maxPersistedHistoryItems = validValue
                return
            }
            defaults.set(validValue, forKey: Key.maxPersistedHistoryItems)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = AppLanguage(rawValue: defaults.string(forKey: Key.language) ?? "") ?? .english
        displayMode = DisplayMode(rawValue: defaults.string(forKey: Key.displayMode) ?? "") ?? .grid
        let savedLimit = defaults.object(forKey: Key.maxHistoryItems) as? Int
        let historyLimit = Self.clampHistoryLimit(savedLimit ?? Self.defaultMaxHistoryItems)
        maxHistoryItems = historyLimit
        automaticPaste = defaults.bool(forKey: Key.automaticPaste)
        automaticPasteShortcut = defaults.object(forKey: Key.automaticPasteShortcut) as? Bool ?? true
        persistHistory = defaults.bool(forKey: Key.persistHistory)
        historyFilePath = defaults.string(forKey: Key.historyFilePath) ?? Self.defaultHistoryFilePath
        let savedPersistedLimit = defaults.object(forKey: Key.maxPersistedHistoryItems) as? Int
        maxPersistedHistoryItems = Self.clampPersistedHistoryLimit(
            savedPersistedLimit ?? historyLimit,
            minimum: historyLimit
        )
    }

    nonisolated static func clampHistoryLimit(_ value: Int) -> Int {
        min(max(value, 1), 100)
    }

    nonisolated static func clampPersistedHistoryLimit(_ value: Int, minimum: Int) -> Int {
        min(max(value, minimum), maximumPersistedHistoryItems)
    }

    var shouldShowLaunchAtLoginPrompt: Bool {
        !defaults.bool(forKey: Key.launchAtLoginPromptShown)
    }

    func markLaunchAtLoginPromptAsShown() {
        defaults.set(true, forKey: Key.launchAtLoginPromptShown)
    }

    func reset() {
        language = .english
        displayMode = .grid
        maxHistoryItems = Self.defaultMaxHistoryItems
        automaticPaste = false
        automaticPasteShortcut = true
    }
}
