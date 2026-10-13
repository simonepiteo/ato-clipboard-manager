import AppKit
import ApplicationServices
import Combine

@MainActor
final class AccessibilityPermissionManager: ObservableObject {
    @Published private(set) var isGranted: Bool

    init() {
        isGranted = AXIsProcessTrusted()
    }

    func refresh() {
        isGranted = AXIsProcessTrusted()
    }

    func requestAndOpenSystemSettings() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

}
