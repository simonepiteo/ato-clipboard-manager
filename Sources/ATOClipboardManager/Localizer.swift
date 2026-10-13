import Foundation

enum LocalizedKey: String {
    case search, clearHistory, settings, quit
    case settingsTitle, language, displayMode, grid, list
    case maxHistory, automaticPaste, automaticPasteShortcut
    case resetSettings, emptyHistory, version
    case settingsDescription, appearance, behavior, sourceCode, license
    case startup, launchAtLogin, launchAtLoginApproval, openLoginItems
    case launchAtLoginPromptTitle, launchAtLoginPromptMessage, enable, notNow
    case launchAtLoginError
}

enum Localizer {
    private static let english: [LocalizedKey: String] = [
        .search: "Search…", .clearHistory: "Clear history", .settings: "Settings…", .quit: "Quit",
        .settingsTitle: "ATO - Clipboard Manager Settings", .language: "Language",
        .displayMode: "Display mode", .grid: "Grid", .list: "List",
        .maxHistory: "Maximum history items", .automaticPaste: "Paste automatically on selection",
        .automaticPasteShortcut: "Paste automatically when using ⌘1–⌘9",
        .resetSettings: "Reset settings", .emptyHistory: "Copy text or an image to get started",
        .settingsDescription: "Customize how ATO displays and pastes your clipboard items.",
        .appearance: "Appearance and history", .behavior: "Paste behavior",
        .sourceCode: "Source code", .license: "License",
        .startup: "Startup", .launchAtLogin: "Launch ATO when you log in",
        .launchAtLoginApproval: "Approval is required in System Settings.",
        .openLoginItems: "Open Login Items", .launchAtLoginPromptTitle: "Launch ATO at login?",
        .launchAtLoginPromptMessage: "ATO can start automatically when you log in, so your clipboard history is always ready.",
        .enable: "Enable", .notNow: "Not now", .launchAtLoginError: "Couldn’t update the login item"
    ]

    private static let italian: [LocalizedKey: String] = [
        .search: "Cerca…", .clearHistory: "Cancella cronologia", .settings: "Impostazioni…", .quit: "Chiudi",
        .settingsTitle: "Impostazioni ATO - Clipboard Manager", .language: "Lingua",
        .displayMode: "Vista elementi", .grid: "Griglia", .list: "Lista",
        .maxHistory: "Massimo numero di elementi", .automaticPaste: "Incolla automaticamente alla selezione",
        .automaticPasteShortcut: "Incolla automaticamente usando ⌘1–⌘9",
        .resetSettings: "Ripristina impostazioni", .emptyHistory: "Copia un testo o un'immagine per iniziare",
        .settingsDescription: "Personalizza la visualizzazione e l'incolla degli elementi copiati.",
        .appearance: "Aspetto e cronologia", .behavior: "Comportamento incolla",
        .sourceCode: "Codice sorgente", .license: "Licenza",
        .startup: "Avvio", .launchAtLogin: "Avvia ATO quando accedi",
        .launchAtLoginApproval: "È necessaria l’approvazione nelle Impostazioni di Sistema.",
        .openLoginItems: "Apri Elementi login", .launchAtLoginPromptTitle: "Avviare ATO all’accesso?",
        .launchAtLoginPromptMessage: "ATO può avviarsi automaticamente quando accedi, così la cronologia degli appunti è sempre pronta.",
        .enable: "Attiva", .notNow: "Non ora", .launchAtLoginError: "Impossibile aggiornare l’elemento di login"
    ]

    static func text(_ key: LocalizedKey, language: AppLanguage) -> String {
        if key == .version {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
            return language == .italian ? "Versione \(version)" : "Version \(version)"
        }
        return (language == .italian ? italian : english)[key] ?? key.rawValue
    }
}
