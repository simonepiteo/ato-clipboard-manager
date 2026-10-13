import Carbon.HIToolbox
import XCTest
@testable import ATOClipboardManager

final class ShortcutSettingsTests: XCTestCase {
    @MainActor
    func testShortcutsAreSavedAndRestored() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShortcutSettingsTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let fileURL = directory.appendingPathComponent("shortcut.json")
        let persistence = ShortcutPersistence(fileURL: fileURL)
        let settings = ShortcutSettings(persistence: persistence)
        let shortcut = AppShortcut(
            keyCode: UInt16(kVK_ANSI_B),
            key: "B",
            modifiers: [.command, .option]
        )

        settings.set(shortcut, for: .togglePopover)

        XCTAssertEqual(settings.shortcut(for: .togglePopover), shortcut)
        XCTAssertEqual(ShortcutSettings(persistence: persistence).shortcut(for: .togglePopover), shortcut)
        XCTAssertEqual(
            try FileManager.default.attributesOfItem(atPath: fileURL.path)[.posixPermissions] as? Int,
            0o600
        )
        let json = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(json.contains("\"version\" : 1"))
        XCTAssertTrue(json.contains("\"togglePopover\""))
    }

    @MainActor
    func testDuplicateShortcutIsRejected() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShortcutDuplicateTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = ShortcutSettings(
            persistence: ShortcutPersistence(fileURL: directory.appendingPathComponent("shortcut.json"))
        )
        let original = settings.shortcut(for: .quit)

        settings.set(settings.shortcut(for: .openSettings), for: .quit)

        XCTAssertEqual(settings.shortcut(for: .quit), original)
        XCTAssertEqual(settings.issue, .duplicate(.openSettings))
    }

    @MainActor
    func testSingleShortcutCanBeRestored() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShortcutResetTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let settings = ShortcutSettings(
            persistence: ShortcutPersistence(fileURL: directory.appendingPathComponent("shortcut.json"))
        )
        let custom = AppShortcut(keyCode: UInt16(kVK_ANSI_B), key: "B", modifiers: [.command, .shift])

        settings.set(custom, for: .togglePopover)
        XCTAssertTrue(settings.isCustomized(.togglePopover))
        settings.reset(.togglePopover)

        XCTAssertFalse(settings.isCustomized(.togglePopover))
        XCTAssertEqual(settings.shortcut(for: .togglePopover), ShortcutSettings.defaultShortcuts[.togglePopover])
    }
}
