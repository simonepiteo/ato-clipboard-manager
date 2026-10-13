import Foundation

enum LocalizedKey: String {
    case search, clearHistory, settings, quit
    case settingsTitle, language, displayMode, grid, list
    case maxHistory, automaticPaste, automaticPasteShortcut
    case resetSettings, emptyHistory, version
    case settingsDescription, appearance, behavior, sourceCode, license
}

enum Localizer {
    private static let english: [LocalizedKey: String] = [
        .search: "Search…", .clearHistory: "Clear history", .settings: "Settings…", .quit: "Quit",
        .settingsTitle: "ATO - Clipboard Manager Settings", .language: "Language",
        .displayMode: "Display mode", .grid: "Grid", .list: "List",
        .maxHistory: "Maximum history items", .automaticPaste: "Paste automatically on selection",
        .automaticPasteShortcut: "Paste automatically when using ⌘1–⌘9",
        .resetSettings: "Reset settings", .emptyHistory: "Copy text or an image to get started",
        .version: "Version 0.1.3", .settingsDescription: "Customize how ATO displays and pastes your clipboard items.",
        .appearance: "Appearance and history", .behavior: "Paste behavior",
        .sourceCode: "Source code", .license: "License"
    ]

    private static let italian: [LocalizedKey: String] = [
        .search: "Cerca…", .clearHistory: "Cancella cronologia", .settings: "Impostazioni…", .quit: "Chiudi",
        .settingsTitle: "Impostazioni ATO - Clipboard Manager", .language: "Lingua",
        .displayMode: "Vista elementi", .grid: "Griglia", .list: "Lista",
        .maxHistory: "Massimo numero di elementi", .automaticPaste: "Incolla automaticamente alla selezione",
        .automaticPasteShortcut: "Incolla automaticamente usando ⌘1–⌘9",
        .resetSettings: "Ripristina impostazioni", .emptyHistory: "Copia un testo o un'immagine per iniziare",
        .version: "Versione 0.1.3", .settingsDescription: "Personalizza la visualizzazione e l'incolla degli elementi copiati.",
        .appearance: "Aspetto e cronologia", .behavior: "Comportamento incolla",
        .sourceCode: "Codice sorgente", .license: "Licenza"
    ]

    static func text(_ key: LocalizedKey, language: AppLanguage) -> String {
        (language == .italian ? italian : english)[key] ?? key.rawValue
    }
}
