import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings()
    lazy var clipboardStore = ClipboardStore(settings: settings)

    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var localKeyMonitor: Any?
    private var hotKeyManager: HotKeyManager?
    private var lastActiveApplication: NSRunningApplication?
    private var actionAfterPopoverCloses: (() -> Void)?
    private var restorePopoverAnimationAfterClose = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configurePopover()
        configureStatusItem()
        configureKeyboardShortcuts()
        clipboardStore.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardStore.stop()
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
    }

    private func configurePopover() {
        let view = PopoverView(
            store: clipboardStore,
            settings: settings,
            select: { [weak self] item, paste, waitForClick in
                self?.select(item, paste: paste, waitForClickCompletion: waitForClick)
            },
            openSettings: { [weak self] in self?.openSettings() },
            quit: { NSApp.terminate(nil) }
        )
        popover.contentSize = NSSize(width: 350, height: 436)
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

    private func configureKeyboardShortcuts() {
        hotKeyManager = HotKeyManager { [weak self] in
            DispatchQueue.main.async { self?.togglePopover() }
        }
        hotKeyManager?.register()

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == .command, let number = Int(event.charactersIgnoringModifiers ?? ""), (1...9).contains(number) {
                NotificationCenter.default.post(
                    name: .selectClipboardHistoryItem,
                    object: nil,
                    userInfo: ["index": number - 1]
                )
                return nil
            }
            if flags == [.command, .option], event.charactersIgnoringModifiers?.lowercased() == "s" {
                Task { @MainActor in self.openSettings() }
                return nil
            }
            return event
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

    private func pasteIntoActiveApplication() {
        guard AXIsProcessTrusted() else {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            return
        }
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
        let controller = NSHostingController(rootView: SettingsView(settings: settings))
        let window = NSWindow(contentViewController: controller)
        window.title = Localizer.text(.settingsTitle, language: settings.language)
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 440, height: 310))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        settingsWindow = window
        popover.performClose(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension Notification.Name {
    static let selectClipboardHistoryItem = Notification.Name("selectClipboardHistoryItem")
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
