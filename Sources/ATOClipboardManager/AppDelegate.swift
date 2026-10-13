import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    let launchAtLogin = LaunchAtLoginManager()
    let updateManager = UpdateManager()
    let shortcutSettings = ShortcutSettings()
    let accessibilityPermission = AccessibilityPermissionManager()
    let favoritesStore = FavoritesStore()
    lazy var clipboardStore = ClipboardStore(settings: settings)

    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var localKeyMonitor: Any?
    private var hotKeyManager: HotKeyManager?
    private var lastActiveApplication: NSRunningApplication?
    private var actionAfterPopoverCloses: (() -> Void)?
    private var restorePopoverAnimationAfterClose = false
    private var updateObservation: AnyCancellable?
    private var shortcutObservation: AnyCancellable?
    private var themeObservation: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        applyTheme(settings.theme)
        configurePopover()
        configureStatusItem()
        configureKeyboardShortcuts()
        observeTheme()
        clipboardStore.start()
        observeAvailableUpdates()
        Task { await updateManager.checkIfNeeded(force: true) }
        DispatchQueue.main.async { [weak self] in
            self?.showLaunchAtLoginPromptIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardStore.stop()
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        accessibilityPermission.refresh()
    }

    private func configurePopover() {
        let view = PopoverView(
            store: clipboardStore,
            settings: settings,
            updateManager: updateManager,
            shortcutSettings: shortcutSettings,
            favoritesStore: favoritesStore,
            select: { [weak self] item, paste, waitForClick in
                self?.select(item, paste: paste, waitForClickCompletion: waitForClick)
            },
            openSettings: { [weak self] in self?.openSettings() },
            quit: { NSApp.terminate(nil) }
        )
        popover.contentSize = NSSize(width: 350, height: 440)
        popover.contentViewController = NSHostingController(rootView: view)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "ATO Clipboard Manager")
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
    }

    private func observeTheme() {
        themeObservation = settings.$theme
            .removeDuplicates()
            .sink { [weak self] theme in
                self?.applyTheme(theme)
            }
    }

    private func applyTheme(_ theme: AppTheme) {
        let appearance = theme.appearance
        NSApp.appearance = appearance
        popover.contentViewController?.view.appearance = appearance
        settingsWindow?.appearance = appearance
    }

    private func observeAvailableUpdates() {
        updateObservation = updateManager.$releases.sink { [weak self] releases in
            guard let self else { return }
            let installed = VersionNumber(self.updateManager.currentVersion)
            let hasUpdate = self.updateManager.currentVersion != "development" && releases.contains {
                VersionNumber($0.version) > installed && $0.dmgAsset != nil
            }
            self.statusItem.button?.attributedTitle = hasUpdate
                ? NSAttributedString(
                    string: " ●",
                    attributes: [
                        .foregroundColor: NSColor.systemRed,
                        .font: NSFont.systemFont(ofSize: 8, weight: .bold)
                    ]
                )
                : NSAttributedString(string: "")
            self.statusItem.button?.toolTip = hasUpdate
                ? Localizer.text(.updateBadgeHint, language: self.settings.language)
                : "ATO Clipboard Manager"
        }
    }

    private func configureKeyboardShortcuts() {
        hotKeyManager = HotKeyManager { [weak self] in
            DispatchQueue.main.async { self?.togglePopover() }
        }
        shortcutObservation = shortcutSettings.$shortcuts.sink { [weak self] shortcuts in
            guard let shortcut = shortcuts[.togglePopover] else { return }
            self?.hotKeyManager?.register(shortcut)
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard !(NSApp.keyWindow?.firstResponder is ShortcutRecorderButton) else { return event }

            let commandModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            if self.popover.isShown, commandModifiers.isEmpty,
               let command = ClipboardKeyboardCommand(event: event) {
                NotificationCenter.default.post(
                    name: .navigateClipboardHistory,
                    object: nil,
                    userInfo: ["command": command.rawValue]
                )
                return nil
            }

            guard let action = self.shortcutSettings.action(matching: event) else { return event }

            if let index = action.itemIndex {
                NotificationCenter.default.post(
                    name: .selectClipboardHistoryItem,
                    object: nil,
                    userInfo: ["index": index]
                )
                return nil
            }

            switch action {
            case .showHistory, .showFavorites:
                NotificationCenter.default.post(
                    name: .switchClipboardSection,
                    object: nil,
                    userInfo: ["section": action == .showFavorites ? "favorites" : "history"]
                )
                return nil
            case .openSettings:
                Task { @MainActor in self.openSettings() }
                return nil
            case .quit:
                NSApp.terminate(nil)
                return nil
            case .togglePopover:
                return event
            default:
                return event
            }
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        guard let button = statusItem.button else { return }
        lastActiveApplication = NSWorkspace.shared.frontmostApplication
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .resetClipboardKeyboardSelection, object: nil)
    }

    private func select(_ item: ClipboardItem, paste: Bool, waitForClickCompletion: Bool) {
        guard clipboardStore.copy(item, moveToFront: !waitForClickCompletion) else { return }

        Task { @MainActor [weak self] in
            if waitForClickCompletion {
                try? await Task.sleep(nanoseconds: 50_000_000)
            } else {
                await Task.yield()
            }

            guard let self else { return }
            if waitForClickCompletion {
                self.clipboardStore.promote(item)
            }
            if paste {
                self.accessibilityPermission.refresh()
                guard self.accessibilityPermission.isGranted else {
                    self.closePopoverAndExplainAccessibility(animated: waitForClickCompletion)
                    return
                }
                self.closePopoverAndPaste(animated: waitForClickCompletion)
            } else {
                self.closePopoverAndRestoreFocus(animated: waitForClickCompletion)
            }
        }
    }

    private func closePopoverAndRestoreFocus(animated: Bool, completion: (() -> Void)? = nil) {
        actionAfterPopoverCloses = { [weak self] in
            self?.lastActiveApplication?.activate(options: [])
            completion?()
        }

        if popover.isShown {
            if !animated {
                restorePopoverAnimationAfterClose = popover.animates
                popover.animates = false
            }
            popover.performClose(nil)
        } else {
            performActionAfterPopoverCloses()
        }
    }

    private func closePopoverAndPaste(animated: Bool) {
        closePopoverAndRestoreFocus(animated: animated) { [weak self] in
            self?.pasteIntoActiveApplication()
        }
    }

    private func closePopoverAndExplainAccessibility(animated: Bool) {
        actionAfterPopoverCloses = { [weak self] in
            self?.showAccessibilityPermissionExplanation()
        }

        if popover.isShown {
            if !animated {
                restorePopoverAnimationAfterClose = popover.animates
                popover.animates = false
            }
            popover.performClose(nil)
        } else {
            performActionAfterPopoverCloses()
        }
    }

    private func showAccessibilityPermissionExplanation() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "hand.raised.fill", accessibilityDescription: nil)
        alert.messageText = Localizer.text(.automaticPastePermissionTitle, language: settings.language)
        alert.informativeText = Localizer.text(.automaticPastePermissionMessage, language: settings.language)
        alert.addButton(withTitle: Localizer.text(.openAccessibilitySettings, language: settings.language))
        alert.addButton(withTitle: Localizer.text(.notNow, language: settings.language))

        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            accessibilityPermission.requestAndOpenSystemSettings()
        } else {
            lastActiveApplication?.activate(options: [])
        }
    }

    private func pasteIntoActiveApplication() {
        guard accessibilityPermission.isGranted else { return }
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let source = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }

    private func performActionAfterPopoverCloses() {
        let action = actionAfterPopoverCloses
        actionAfterPopoverCloses = nil
        action?()
    }

    private func openSettings() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = NSHostingController(
            rootView: SettingsView(
                settings: settings,
                launchAtLogin: launchAtLogin,
                clipboardStore: clipboardStore,
                updateManager: updateManager,
                shortcutSettings: shortcutSettings,
                accessibilityPermission: accessibilityPermission
            )
        )
        let window = NSWindow(contentViewController: controller)
        window.title = Localizer.text(.settingsTitle, language: settings.language)
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 820, height: 620))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        settingsWindow = window
        popover.performClose(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showLaunchAtLoginPromptIfNeeded() {
        guard settings.shouldShowLaunchAtLoginPrompt else { return }
        settings.markLaunchAtLoginPromptAsShown()

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = Localizer.text(.launchAtLoginPromptTitle, language: settings.language)
        alert.informativeText = Localizer.text(.launchAtLoginPromptMessage, language: settings.language)
        alert.addButton(withTitle: Localizer.text(.enable, language: settings.language))
        alert.addButton(withTitle: Localizer.text(.notNow, language: settings.language))

        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            launchAtLogin.setEnabled(true)
            showLaunchAtLoginFollowUpIfNeeded()
        }
    }

    private func showLaunchAtLoginFollowUpIfNeeded() {
        if let errorMessage = launchAtLogin.errorMessage {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = Localizer.text(.launchAtLoginError, language: settings.language)
            alert.informativeText = errorMessage
            alert.runModal()
            return
        }

        guard launchAtLogin.requiresApproval else { return }
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = Localizer.text(.launchAtLoginApproval, language: settings.language)
        alert.addButton(withTitle: Localizer.text(.openLoginItems, language: settings.language))
        alert.addButton(withTitle: Localizer.text(.notNow, language: settings.language))
        if alert.runModal() == .alertFirstButtonReturn {
            launchAtLogin.openSystemSettings()
        }
    }
}

extension Notification.Name {
    static let selectClipboardHistoryItem = Notification.Name("selectClipboardHistoryItem")
    static let switchClipboardSection = Notification.Name("switchClipboardSection")
    static let navigateClipboardHistory = Notification.Name("navigateClipboardHistory")
    static let resetClipboardKeyboardSelection = Notification.Name("resetClipboardKeyboardSelection")
}

enum ClipboardKeyboardCommand: String {
    case moveLeft, moveRight, moveUp, moveDown, select

    init?(event: NSEvent) {
        switch event.keyCode {
        case 123: self = .moveLeft
        case 124: self = .moveRight
        case 125: self = .moveDown
        case 126: self = .moveUp
        case 36, 76: self = .select
        default: return nil
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        if restorePopoverAnimationAfterClose {
            popover.animates = true
            restorePopoverAnimationAfterClose = false
        }
        performActionAfterPopoverCloses()
    }
}
