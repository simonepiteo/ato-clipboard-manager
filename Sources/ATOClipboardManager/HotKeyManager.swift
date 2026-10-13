import Carbon.HIToolbox
import Foundation

final class HotKeyManager {
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    func register(_ shortcut: AppShortcut) {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
            self.hotKey = nil
        }

        if eventHandler == nil {
            installEventHandler()
        }

        let identifier = EventHotKeyID(signature: OSType(0x41544F21), id: 1) // ATO!
        RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.carbonModifiers,
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue().action()
            return noErr
        }, 1, &eventType, pointer, &eventHandler)
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
