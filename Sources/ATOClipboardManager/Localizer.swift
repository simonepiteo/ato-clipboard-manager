import Foundation

enum LocalizedKey: String {
    case search, clearHistory, settings, quit
    case settingsTitle, language, displayMode, grid, list
    case maxHistory, automaticPaste, automaticPasteShortcut
    case resetSettings, emptyHistory, version
    case settingsDescription, appearance, behavior, sourceCode, license, general
    case generalSettingsDescription, behaviorSettingsDescription, startupSettingsDescription
    case storageSettingsDescription, updatesSettingsDescription
    case shortcuts, shortcutsSettingsDescription, applicationShortcuts, historyShortcuts
    case openPopoverShortcut, openSettingsShortcut, quitShortcut, selectItemShortcut
    case showHistoryShortcut, showFavoritesShortcut
    case recordShortcut, resetShortcut, resetShortcuts, shortcutError, shortcutModifierRequired, shortcutDuplicate
    case startup, launchAtLogin, launchAtLoginApproval, openLoginItems
    case launchAtLoginPromptTitle, launchAtLoginPromptMessage, enable, notNow
    case launchAtLoginError
    case storage, persistHistory, persistedHistoryLimit
    case deletePersistedHistory
    case historyPersistenceError
    case disablePersistenceTitle, disablePersistenceMessage, keepPersistedHistory
    case updates, checkForUpdates, updateAvailable, upToDate, lastChecked
    case downloadAndInstall, downloadAndRestartHint, previousVersions, noVersionsLoaded
    case installed, releaseNotes, updateError
    case updateNow, installingUpdate, updateBadgeHint, later
    case accessibilityPermissionRequired, accessibilityPermissionExplanation
    case openAccessibilitySettings, automaticPastePermissionTitle, automaticPastePermissionMessage
    case history, favorites, emptyFavorites, noSearchResults
    case addToFavorites, removeFromFavorites, favoritesPersistenceError
}

enum Localizer {
    private static let english: [LocalizedKey: String] = [
        .search: "Search…", .clearHistory: "Clear history", .settings: "Settings…", .quit: "Quit",
        .settingsTitle: "ATO - Clipboard Manager Settings", .language: "Language",
        .displayMode: "Display mode", .grid: "Grid", .list: "List",
        .maxHistory: "Maximum history items", .automaticPaste: "Paste automatically on selection",
        .automaticPasteShortcut: "Paste automatically when using item shortcuts",
        .resetSettings: "Reset settings", .emptyHistory: "Copy text or an image to get started",
        .settingsDescription: "Customize how ATO displays and pastes your clipboard items.",
        .appearance: "Appearance and history", .behavior: "Paste behavior",
        .general: "General", .generalSettingsDescription: "Language, layout, and visible clipboard history.",
        .behaviorSettingsDescription: "Choose what happens after selecting a clipboard item.",
        .startupSettingsDescription: "Control how ATO starts with your Mac.",
        .storageSettingsDescription: "Keep clipboard history available between launches.",
        .updatesSettingsDescription: "Check your version and browse previous releases.",
        .shortcuts: "Shortcuts", .shortcutsSettingsDescription: "Personalize every keyboard command used by ATO.",
        .applicationShortcuts: "Application", .historyShortcuts: "Clipboard items",
        .openPopoverShortcut: "Open clipboard history", .openSettingsShortcut: "Open Settings",
        .quitShortcut: "Quit ATO", .selectItemShortcut: "Select item %d",
        .showHistoryShortcut: "Show History tab", .showFavoritesShortcut: "Show Favorites tab",
        .recordShortcut: "Press shortcut…", .resetShortcut: "Restore this shortcut",
        .resetShortcuts: "Restore Default Shortcuts",
        .shortcutError: "Invalid shortcut",
        .shortcutModifierRequired: "Use at least one modifier key: Command, Option, Control, or Shift.",
        .shortcutDuplicate: "This shortcut is already assigned to “%@”.",
        .sourceCode: "Source code", .license: "License",
        .startup: "Startup", .launchAtLogin: "Launch ATO when you log in",
        .launchAtLoginApproval: "Approval is required in System Settings.",
        .openLoginItems: "Open Login Items", .launchAtLoginPromptTitle: "Launch ATO at login?",
        .launchAtLoginPromptMessage: "ATO can start automatically when you log in, so your clipboard history is always ready.",
        .enable: "Enable", .notNow: "Not now", .launchAtLoginError: "Couldn’t update the login item",
        .storage: "Storage", .persistHistory: "Save clipboard history to a JSON file",
        .persistedHistoryLimit: "Maximum saved items",
        .deletePersistedHistory: "Delete saved history", .historyPersistenceError: "Couldn’t update the saved history",
        .disablePersistenceTitle: "Delete the saved history?",
        .disablePersistenceMessage: "History saving is now off. Do you also want to delete the history file stored on this Mac? Items currently visible in ATO will remain available until the app quits.",
        .keepPersistedHistory: "Keep File",
        .updates: "Updates", .checkForUpdates: "Check for Updates",
        .updateAvailable: "Version %@ is available", .upToDate: "ATO is up to date",
        .lastChecked: "Last checked: %@", .downloadAndInstall: "Download and Install",
        .downloadAndRestartHint: "ATO will restart after installing the update.",
        .previousVersions: "Previous versions", .noVersionsLoaded: "No release information loaded yet.",
        .installed: "Installed", .releaseNotes: "Open release notes", .updateError: "Couldn’t update ATO",
        .updateNow: "Update Now",
        .installingUpdate: "Downloading and installing…", .updateBadgeHint: "An ATO update is available",
        .later: "Later",
        .accessibilityPermissionRequired: "Accessibility permission required",
        .accessibilityPermissionExplanation: "ATO uses Accessibility only to send ⌘V to the previously active app.",
        .openAccessibilitySettings: "Open Accessibility Settings",
        .automaticPastePermissionTitle: "Allow ATO to paste automatically?",
        .automaticPastePermissionMessage: "The item has been copied, but ATO cannot paste it automatically without Accessibility permission.\n\nATO uses this permission only to send ⌘V to the app you were previously using. It does not use it to read what you type or control other Mac features.\n\nYou can grant access now, or return to the destination app and press ⌘V manually.",
        .history: "History", .favorites: "Favorites",
        .emptyFavorites: "Right-click an item to add it to Favorites",
        .noSearchResults: "No matching items",
        .addToFavorites: "Add to Favorites", .removeFromFavorites: "Remove from Favorites",
        .favoritesPersistenceError: "Couldn’t update Favorites"
    ]

    private static let italian: [LocalizedKey: String] = [
        .search: "Cerca…", .clearHistory: "Cancella cronologia", .settings: "Impostazioni…", .quit: "Chiudi",
        .settingsTitle: "Impostazioni ATO - Clipboard Manager", .language: "Lingua",
        .displayMode: "Vista elementi", .grid: "Griglia", .list: "Lista",
        .maxHistory: "Massimo numero di elementi", .automaticPaste: "Incolla automaticamente alla selezione",
        .automaticPasteShortcut: "Incolla automaticamente usando le scorciatoie degli elementi",
        .resetSettings: "Ripristina impostazioni", .emptyHistory: "Copia un testo o un'immagine per iniziare",
        .settingsDescription: "Personalizza la visualizzazione e l'incolla degli elementi copiati.",
        .appearance: "Aspetto e cronologia", .behavior: "Comportamento incolla",
        .general: "Generali", .generalSettingsDescription: "Lingua, layout e cronologia visibile degli appunti.",
        .behaviorSettingsDescription: "Scegli cosa accade dopo la selezione di un elemento.",
        .startupSettingsDescription: "Controlla come ATO si avvia insieme al Mac.",
        .storageSettingsDescription: "Mantieni la cronologia disponibile tra un avvio e l’altro.",
        .updatesSettingsDescription: "Controlla la versione e consulta le release precedenti.",
        .shortcuts: "Scorciatoie", .shortcutsSettingsDescription: "Personalizza tutti i comandi da tastiera usati da ATO.",
        .applicationShortcuts: "Applicazione", .historyShortcuts: "Elementi degli appunti",
        .openPopoverShortcut: "Apri cronologia appunti", .openSettingsShortcut: "Apri Impostazioni",
        .quitShortcut: "Chiudi ATO", .selectItemShortcut: "Seleziona elemento %d",
        .showHistoryShortcut: "Mostra tab Cronologia", .showFavoritesShortcut: "Mostra tab Preferiti",
        .recordShortcut: "Premi scorciatoia…", .resetShortcut: "Ripristina questa scorciatoia",
        .resetShortcuts: "Ripristina scorciatoie predefinite",
        .shortcutError: "Scorciatoia non valida",
        .shortcutModifierRequired: "Usa almeno un modificatore: Comando, Opzione, Controllo o Maiuscole.",
        .shortcutDuplicate: "Questa scorciatoia è già assegnata a “%@”.",
        .sourceCode: "Codice sorgente", .license: "Licenza",
        .startup: "Avvio", .launchAtLogin: "Avvia ATO quando accedi",
        .launchAtLoginApproval: "È necessaria l’approvazione nelle Impostazioni di Sistema.",
        .openLoginItems: "Apri Elementi login", .launchAtLoginPromptTitle: "Avviare ATO all’accesso?",
        .launchAtLoginPromptMessage: "ATO può avviarsi automaticamente quando accedi, così la cronologia degli appunti è sempre pronta.",
        .enable: "Attiva", .notNow: "Non ora", .launchAtLoginError: "Impossibile aggiornare l’elemento di login",
        .storage: "Archiviazione", .persistHistory: "Salva la cronologia degli appunti in un file JSON",
        .persistedHistoryLimit: "Massimo elementi salvati",
        .deletePersistedHistory: "Elimina cronologia salvata", .historyPersistenceError: "Impossibile aggiornare la cronologia salvata",
        .disablePersistenceTitle: "Eliminare la cronologia salvata?",
        .disablePersistenceMessage: "Il salvataggio è ora disattivato. Vuoi eliminare anche il file della cronologia presente sul Mac? Gli elementi attualmente visibili resteranno disponibili fino alla chiusura dell’app.",
        .keepPersistedHistory: "Mantieni file",
        .updates: "Aggiornamenti", .checkForUpdates: "Cerca aggiornamenti",
        .updateAvailable: "È disponibile la versione %@", .upToDate: "ATO è aggiornato",
        .lastChecked: "Ultimo controllo: %@", .downloadAndInstall: "Scarica e installa",
        .downloadAndRestartHint: "ATO verrà riavviato dopo l’installazione.",
        .previousVersions: "Versioni precedenti", .noVersionsLoaded: "Nessuna informazione sulle release caricata.",
        .installed: "Installata", .releaseNotes: "Apri note di rilascio", .updateError: "Impossibile aggiornare ATO",
        .updateNow: "Aggiorna ora",
        .installingUpdate: "Download e installazione…", .updateBadgeHint: "È disponibile un aggiornamento di ATO",
        .later: "Più tardi",
        .accessibilityPermissionRequired: "Permesso Accessibilità richiesto",
        .accessibilityPermissionExplanation: "ATO usa Accessibilità esclusivamente per inviare ⌘V all’app attiva in precedenza.",
        .openAccessibilitySettings: "Apri Impostazioni Accessibilità",
        .automaticPastePermissionTitle: "Consentire ad ATO di incollare automaticamente?",
        .automaticPastePermissionMessage: "L’elemento è stato copiato, ma ATO non può incollarlo automaticamente senza il permesso Accessibilità.\n\nATO usa questo permesso esclusivamente per inviare ⌘V all’app che stavi usando. Non lo utilizza per leggere ciò che digiti o controllare altre funzioni del Mac.\n\nPuoi concedere il permesso ora oppure tornare all’app di destinazione e premere ⌘V manualmente.",
        .history: "Cronologia", .favorites: "Preferiti",
        .emptyFavorites: "Fai clic destro su un elemento per aggiungerlo ai Preferiti",
        .noSearchResults: "Nessun elemento corrispondente",
        .addToFavorites: "Aggiungi ai Preferiti", .removeFromFavorites: "Rimuovi dai Preferiti",
        .favoritesPersistenceError: "Impossibile aggiornare i Preferiti"
    ]

    static func text(_ key: LocalizedKey, language: AppLanguage) -> String {
        if key == .version {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "development"
            return language == .italian ? "Versione \(version)" : "Version \(version)"
        }
        return (language == .italian ? italian : english)[key] ?? key.rawValue
    }
}
