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
    case storage, persistHistory, historyFilePath, persistedHistoryLimit
    case deletePersistedHistory, deletePersistedHistoryTitle, deletePersistedHistoryMessage, delete
    case historyPersistenceError
    case updates, checkForUpdates, updateAvailable, upToDate, lastChecked
    case downloadAndInstall, downloadAndRestartHint, previousVersions, noVersionsLoaded
    case installed, releaseNotes, updateError
    case updateNow, installingUpdate, updateBadgeHint, later
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
        .enable: "Enable", .notNow: "Not now", .launchAtLoginError: "Couldn’t update the login item",
        .storage: "Storage", .persistHistory: "Save clipboard history to a JSON file",
        .historyFilePath: "File path", .persistedHistoryLimit: "Maximum saved items",
        .deletePersistedHistory: "Delete saved history", .deletePersistedHistoryTitle: "Delete saved history?",
        .deletePersistedHistoryMessage: "This permanently deletes the JSON history file. Items currently visible in ATO are not removed.",
        .delete: "Delete", .historyPersistenceError: "Couldn’t update the saved history",
        .updates: "Updates", .checkForUpdates: "Check for Updates",
        .updateAvailable: "Version %@ is available", .upToDate: "ATO is up to date",
        .lastChecked: "Last checked: %@", .downloadAndInstall: "Download and Install",
        .downloadAndRestartHint: "ATO will restart after installing the update.",
        .previousVersions: "Previous versions", .noVersionsLoaded: "No release information loaded yet.",
        .installed: "Installed", .releaseNotes: "Open release notes", .updateError: "Couldn’t update ATO",
        .updateNow: "Update Now",
        .installingUpdate: "Downloading and installing…", .updateBadgeHint: "An ATO update is available",
        .later: "Later"
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
        .enable: "Attiva", .notNow: "Non ora", .launchAtLoginError: "Impossibile aggiornare l’elemento di login",
        .storage: "Archiviazione", .persistHistory: "Salva la cronologia degli appunti in un file JSON",
        .historyFilePath: "Percorso file", .persistedHistoryLimit: "Massimo elementi salvati",
        .deletePersistedHistory: "Elimina cronologia salvata", .deletePersistedHistoryTitle: "Eliminare la cronologia salvata?",
        .deletePersistedHistoryMessage: "Questa azione elimina definitivamente il file JSON. Gli elementi attualmente visibili in ATO non vengono rimossi.",
        .delete: "Elimina", .historyPersistenceError: "Impossibile aggiornare la cronologia salvata",
        .updates: "Aggiornamenti", .checkForUpdates: "Cerca aggiornamenti",
        .updateAvailable: "È disponibile la versione %@", .upToDate: "ATO è aggiornato",
        .lastChecked: "Ultimo controllo: %@", .downloadAndInstall: "Scarica e installa",
        .downloadAndRestartHint: "ATO verrà riavviato dopo l’installazione.",
        .previousVersions: "Versioni precedenti", .noVersionsLoaded: "Nessuna informazione sulle release caricata.",
        .installed: "Installata", .releaseNotes: "Apri note di rilascio", .updateError: "Impossibile aggiornare ATO",
        .updateNow: "Aggiorna ora",
        .installingUpdate: "Download e installazione…", .updateBadgeHint: "È disponibile un aggiornamento di ATO",
        .later: "Più tardi"
    ]

    static func text(_ key: LocalizedKey, language: AppLanguage) -> String {
        if key == .version {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
            return language == .italian ? "Versione \(version)" : "Version \(version)"
        }
        return (language == .italian ? italian : english)[key] ?? key.rawValue
    }
}
