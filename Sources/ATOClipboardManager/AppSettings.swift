import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let language = "language"
        static let theme = "theme"
        static let displayMode = "displayMode"
        static let maxHistoryItems = "maxHistoryItems"
        static let automaticPaste = "automaticPaste"
        static let automaticPasteShortcut = "automaticPasteShortcut"
        static let automaticPasteOnReturn = "automaticPasteOnReturn"
        static let launchAtLoginPromptShown = "launchAtLoginPromptShown"
        static let persistHistory = "persistHistory"
        static let maxPersistedHistoryItems = "maxPersistedHistoryItems"
        static let hoverZoomEnabled = "hoverZoomEnabled"
        static let hoverZoomDelay = "hoverZoomDelay"
    }

    static let defaultMaxHistoryItems = 20
    nonisolated static let defaultHoverZoomDelay = 3
    nonisolated static let hoverZoomDelayRange = 1...30
    nonisolated static let defaultHistoryFilePath = "~/.ato/history.json"
    nonisolated static let maximumPersistedHistoryItems = 10_000
    private let defaults: UserDefaults

    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: Key.language) } }
    @Published var theme: AppTheme { didSet { defaults.set(theme.rawValue, forKey: Key.theme) } }
    @Published var displayMode: DisplayMode { didSet { defaults.set(displayMode.rawValue, forKey: Key.displayMode) } }
    @Published var hoverZoomEnabled: Bool { didSet { defaults.set(hoverZoomEnabled, forKey: Key.hoverZoomEnabled) } }
    @Published var hoverZoomDelay: Int {
        didSet {
            let validValue = Self.clampHoverZoomDelay(hoverZoomDelay)
            if hoverZoomDelay != validValue { hoverZoomDelay = validValue }
            defaults.set(validValue, forKey: Key.hoverZoomDelay)
        }
    }
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
    @Published var automaticPasteOnReturn: Bool {
        didSet { defaults.set(automaticPasteOnReturn, forKey: Key.automaticPasteOnReturn) }
    }
    @Published var persistHistory: Bool { didSet { defaults.set(persistHistory, forKey: Key.persistHistory) } }
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
        theme = AppTheme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .system
        displayMode = DisplayMode(rawValue: defaults.string(forKey: Key.displayMode) ?? "") ?? .grid
        hoverZoomEnabled = defaults.object(forKey: Key.hoverZoomEnabled) as? Bool ?? true
        hoverZoomDelay = Self.clampHoverZoomDelay(
            defaults.object(forKey: Key.hoverZoomDelay) as? Int ?? Self.defaultHoverZoomDelay
        )
        let savedLimit = defaults.object(forKey: Key.maxHistoryItems) as? Int
        let historyLimit = Self.clampHistoryLimit(savedLimit ?? Self.defaultMaxHistoryItems)
        maxHistoryItems = historyLimit
        automaticPaste = defaults.bool(forKey: Key.automaticPaste)
        automaticPasteShortcut = defaults.object(forKey: Key.automaticPasteShortcut) as? Bool ?? true
        automaticPasteOnReturn = defaults.bool(forKey: Key.automaticPasteOnReturn)
        persistHistory = defaults.bool(forKey: Key.persistHistory)
        let savedPersistedLimit = defaults.object(forKey: Key.maxPersistedHistoryItems) as? Int
        maxPersistedHistoryItems = Self.clampPersistedHistoryLimit(
            savedPersistedLimit ?? historyLimit,
            minimum: historyLimit
        )
    }

    nonisolated static func clampHistoryLimit(_ value: Int) -> Int {
        min(max(value, 1), 100)
    }

    nonisolated static func clampHoverZoomDelay(_ value: Int) -> Int {
        min(max(value, hoverZoomDelayRange.lowerBound), hoverZoomDelayRange.upperBound)
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
        theme = .system
        displayMode = .grid
        hoverZoomEnabled = true
        hoverZoomDelay = Self.defaultHoverZoomDelay
        maxHistoryItems = Self.defaultMaxHistoryItems
        automaticPaste = false
        automaticPasteShortcut = true
        automaticPasteOnReturn = false
    }
}
