import AppKit
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    let shortcut: AppShortcut
    let prompt: String
    let onRecord: (AppShortcut) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let button = ShortcutRecorderButton()
        button.onRecord = onRecord
        button.prompt = prompt
        button.shortcut = shortcut
        return button
    }

    func updateNSView(_ button: ShortcutRecorderButton, context: Context) {
        button.onRecord = onRecord
        button.prompt = prompt
        button.shortcut = shortcut
        button.refreshTitle()
    }
}

final class ShortcutRecorderButton: NSButton {
    var shortcut: AppShortcut?
    var prompt = ""
    var onRecord: ((AppShortcut) -> Void)?
    private var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        title = ""
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(beginRecording)
        focusRingType = .exterior
        setAccessibilityLabel("Keyboard shortcut")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    @objc private func beginRecording() {
        isRecording = true
        title = prompt
        window?.makeFirstResponder(self)
    }

    func refreshTitle() {
        guard !isRecording else { return }
        title = shortcut?.displayString ?? "—"
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        refreshTitle()
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        record(event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else { return super.performKeyEquivalent(with: event) }
        record(event)
        return true
    }

    private func record(_ event: NSEvent) {
        guard isRecording else { return }
        let shortcutModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if event.keyCode == 53, shortcutModifiers.isEmpty {
            window?.makeFirstResponder(nil)
            return
        }
        let shortcut = AppShortcut(event: event)
        isRecording = false
        onRecord?(shortcut)
        window?.makeFirstResponder(nil)
        refreshTitle()
    }
}
