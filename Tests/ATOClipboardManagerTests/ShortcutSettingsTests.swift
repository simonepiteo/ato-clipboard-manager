import AppKit
import Carbon.HIToolbox
import XCTest
@testable import ATOClipboardManager

final class ShortcutSettingsTests: XCTestCase {
    @MainActor
    func testZoomShortcutCanBeCustomizedRestoredAndRejectsDuplicates() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = ShortcutPersistence(fileURL: directory.appendingPathComponent("shortcut.json"))
        let settings = ShortcutSettings(persistence: persistence)
        let standard = AppShortcut(keyCode: UInt16(kVK_ANSI_Z), key: "Z", modifiers: [.command, .option])
        XCTAssertEqual(settings.shortcut(for: .zoomSelectedItem), standard)
        let custom = AppShortcut(keyCode: UInt16(kVK_ANSI_B), key: "B", modifiers: [.command, .shift])
        settings.set(custom, for: .zoomSelectedItem)
        let restored = ShortcutSettings(persistence: persistence)
        let event = try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.command, .shift],
            timestamp: 0, windowNumber: 0, context: nil, characters: "b",
            charactersIgnoringModifiers: "b", isARepeat: false, keyCode: UInt16(kVK_ANSI_B)
        ))
        XCTAssertEqual(restored.action(matching: event), .zoomSelectedItem)
        restored.set(custom, for: .quit)
        XCTAssertEqual(restored.issue, .duplicate(.zoomSelectedItem))
        restored.reset(.zoomSelectedItem)
        XCTAssertEqual(restored.shortcut(for: .zoomSelectedItem), standard)
    }

    @MainActor
    func testNewZoomShortcutPreservesExistingBindingsEvenWhenItsDefaultIsTaken() throws {
        for takesZoomDefault in [false, true] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let persistence = ShortcutPersistence(fileURL: directory.appendingPathComponent("shortcut.json"))
            var saved = ShortcutSettings.defaultShortcuts
            saved.removeValue(forKey: .zoomSelectedItem)
            let customPin = takesZoomDefault
                ? ShortcutSettings.defaultShortcuts[.zoomSelectedItem]!
                : AppShortcut(keyCode: UInt16(kVK_ANSI_B), key: "B", modifiers: [.command, .option])
            saved[.toggleSelectedItemPin] = customPin
            try persistence.save(saved)
            let settings = ShortcutSettings(persistence: persistence)
            XCTAssertNil(settings.issue)
            for (action, shortcut) in saved { XCTAssertEqual(settings.shortcut(for: action), shortcut) }
            XCTAssertNotEqual(settings.shortcut(for: .zoomSelectedItem), customPin)
            XCTAssertEqual(Set(settings.shortcuts.values).count, settings.shortcuts.count)
        }
    }

    @MainActor
    func testSelectionModeShortcutMatchesCustomizedAssignmentAfterRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SelectionShortcutTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = ShortcutPersistence(fileURL: directory.appendingPathComponent("shortcut.json"))
        let settings = ShortcutSettings(persistence: persistence)
        let defaultShortcut = AppShortcut(keyCode: UInt16(kVK_ANSI_M), key: "M", modifiers: [.command, .shift])
        XCTAssertEqual(settings.shortcut(for: .enterSelectionMode), defaultShortcut)

        let custom = AppShortcut(keyCode: UInt16(kVK_ANSI_B), key: "B", modifiers: [.command, .option])
        settings.set(custom, for: .enterSelectionMode)
        let restored = ShortcutSettings(persistence: persistence)
        let event = try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.command, .option],
            timestamp: 0, windowNumber: 0, context: nil,
            characters: "b", charactersIgnoringModifiers: "b", isARepeat: false,
            keyCode: UInt16(kVK_ANSI_B)
        ))
        XCTAssertEqual(restored.action(matching: event), .enterSelectionMode)
        restored.set(custom, for: .quit)
        XCTAssertEqual(restored.issue, .duplicate(.enterSelectionMode))
        restored.reset(.enterSelectionMode)
        XCTAssertEqual(restored.shortcut(for: .enterSelectionMode), defaultShortcut)
    }

    @MainActor
    func testSelectionModeShortcutIsAddedWithoutReplacingExistingAssignments() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SelectionShortcutMigrationTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = ShortcutPersistence(fileURL: directory.appendingPathComponent("shortcut.json"))
        var saved = ShortcutSettings.defaultShortcuts
        saved.removeValue(forKey: .enterSelectionMode)
        let customPin = AppShortcut(keyCode: UInt16(kVK_ANSI_P), key: "P", modifiers: [.command, .option])
        saved[.toggleSelectedItemPin] = customPin
        try persistence.save(saved)

        let settings = ShortcutSettings(persistence: persistence)
        XCTAssertNil(settings.issue)
        XCTAssertEqual(settings.shortcut(for: .toggleSelectedItemPin), customPin)
        XCTAssertEqual(settings.shortcut(for: .enterSelectionMode), ShortcutSettings.defaultShortcuts[.enterSelectionMode])
    }

    @MainActor
    func testPinShortcutDefaultsToCommandPAndCanBeCustomizedAndRestored() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PinShortcutTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = ShortcutPersistence(fileURL: directory.appendingPathComponent("shortcut.json"))
        let settings = ShortcutSettings(persistence: persistence)
        let commandP = AppShortcut(keyCode: UInt16(kVK_ANSI_P), key: "P", modifiers: [.command])
        let custom = AppShortcut(keyCode: UInt16(kVK_ANSI_P), key: "P", modifiers: [.command, .shift])

        XCTAssertEqual(settings.shortcut(for: .toggleSelectedItemPin), commandP)
        settings.set(custom, for: .toggleSelectedItemPin)
        let restored = ShortcutSettings(persistence: persistence)
        XCTAssertEqual(restored.shortcut(for: .toggleSelectedItemPin), custom)
        XCTAssertTrue(restored.isCustomized(.toggleSelectedItemPin))
        restored.reset(.toggleSelectedItemPin)
        XCTAssertEqual(restored.shortcut(for: .toggleSelectedItemPin), commandP)
        XCTAssertFalse(restored.isCustomized(.toggleSelectedItemPin))

        restored.set(commandP, for: .quit)
        XCTAssertEqual(restored.issue, .duplicate(.toggleSelectedItemPin))
    }

    @MainActor
    func testPinShortcutIsAddedToExistingSavedShortcuts() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PinShortcutMigrationTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = ShortcutPersistence(fileURL: directory.appendingPathComponent("shortcut.json"))
        var previousShortcuts = ShortcutSettings.defaultShortcuts
        previousShortcuts.removeValue(forKey: .toggleSelectedItemPin)
        let custom = AppShortcut(keyCode: UInt16(kVK_ANSI_B), key: "B", modifiers: [.command, .option])
        previousShortcuts[.togglePopover] = custom
        try persistence.save(previousShortcuts)

        let settings = ShortcutSettings(persistence: persistence)

        XCTAssertNil(settings.issue)
        XCTAssertEqual(settings.shortcut(for: .togglePopover), custom)
        XCTAssertEqual(settings.shortcut(for: .toggleSelectedItemPin), ShortcutSettings.defaultShortcuts[.toggleSelectedItemPin])
    }

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
        XCTAssertTrue(json.contains("\"showHistory\""))
        XCTAssertTrue(json.contains("\"showFavorites\""))
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
