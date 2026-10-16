import Foundation
import XCTest
@testable import ATOClipboardManager

final class HistoryPersistenceTests: XCTestCase {
    @MainActor
    func testGroupPinTogglePinsMixedSelectionThenUnpinsOnlySelectedItems() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GroupPinToggleTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("favorites.json").path
        let first = ClipboardItem(content: .text("first"))
        let second = ClipboardItem(content: .text("second"))
        let other = ClipboardItem(content: .text("other"))
        let store = FavoritesStore(filePath: path)
        store.setPinned(true, for: [first, other])

        XCTAssertTrue(store.toggle([first, second]))
        XCTAssertTrue(store.contains(first))
        XCTAssertTrue(store.contains(second))
        XCTAssertTrue(store.contains(other))
        XCTAssertEqual(FavoritesStore(filePath: path).items, store.items)

        XCTAssertTrue(store.toggle([first, second]))
        XCTAssertEqual(store.items, [other])
        XCTAssertEqual(FavoritesStore(filePath: path).items, [other])
        XCTAssertFalse(store.toggle([]))
        XCTAssertEqual(store.items, [other])
    }

    @MainActor
    func testBatchPinningAndUnpinningArePersistedWithoutDuplicates() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BatchFavoritesTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("favorites.json").path
        let first = ClipboardItem(content: .text("first"))
        let second = ClipboardItem(content: .text("second"))
        let third = ClipboardItem(content: .text("third"))
        let store = FavoritesStore(filePath: path)
        store.toggle(first)

        XCTAssertTrue(store.setPinned(true, for: [first, second, second, third]))
        XCTAssertEqual(store.items, [second, third, first])
        XCTAssertEqual(FavoritesStore(filePath: path).items, store.items)

        XCTAssertTrue(store.setPinned(false, for: [first, third]))
        XCTAssertEqual(store.items, [second])
        XCTAssertEqual(FavoritesStore(filePath: path).items, [second])
    }

    @MainActor
    func testBatchPinFailureRestoresTheWholePreviousSelection() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BatchFavoritesFailureTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("favorites.json").path
        let first = ClipboardItem(content: .text("first"))
        let store = FavoritesStore(filePath: path)
        store.toggle(first)
        try FileManager.default.removeItem(atPath: path)
        try FileManager.default.removeItem(at: directory)
        try Data().write(to: directory)

        XCTAssertFalse(store.setPinned(false, for: [first]))
        XCTAssertEqual(store.items, [first])
        XCTAssertNotNil(store.persistenceError)
        XCTAssertFalse(store.setPinned(true, for: [ClipboardItem(content: .text("second"))]))
        XCTAssertEqual(store.items, [first])
    }

    @MainActor
    func testBatchDeletionUpdatesPersistenceAndRollsBackOnSaveFailure() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BatchDeletionTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("history.json").path
        let suiteName = "BatchDeletionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "persistHistory")
        let store = ClipboardStore(settings: AppSettings(defaults: defaults), historyFilePath: path)
        let first = ClipboardItem(content: .text("first"))
        let second = ClipboardItem(content: .text("second"))
        let third = ClipboardItem(content: .text("third"))
        store.promote(first)
        store.promote(second)
        store.promote(third)

        XCTAssertTrue(store.delete([first, third]))
        XCTAssertEqual(store.items, [second])
        XCTAssertEqual(try HistoryPersistence().load(from: path), [second])

        store.promote(first)
        try FileManager.default.removeItem(atPath: path)
        try FileManager.default.removeItem(at: directory)
        try Data().write(to: directory)

        XCTAssertFalse(store.delete([first, second]))
        XCTAssertEqual(store.items, [first, second])
        XCTAssertNotNil(store.persistenceError)
    }

    @MainActor
    func testFavoritesAreToggledAndRestored() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FavoritesStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("favorites.json").path
        let first = ClipboardItem(content: .text("first"))
        let second = ClipboardItem(content: .text("second"))

        let store = FavoritesStore(filePath: path)
        store.toggle(first)
        store.toggle(second)

        XCTAssertEqual(store.items.map(\.searchableText), ["second", "first"])
        XCTAssertTrue(store.contains(first))
        XCTAssertEqual(FavoritesStore(filePath: path).items.map(\.searchableText), ["second", "first"])
        XCTAssertEqual(
            try FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? Int,
            0o600
        )

        store.toggle(first)
        XCTAssertFalse(store.contains(first))
        XCTAssertEqual(FavoritesStore(filePath: path).items.map(\.searchableText), ["second"])
    }

    func testJSONRoundTripAndDeletion() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HistoryPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("history.json").path
        let persistence = HistoryPersistence()
        let expected = [
            ClipboardItem(content: .text("hello")),
            ClipboardItem(content: .image(Data([0x01, 0x02, 0x03]))),
            ClipboardItem(content: .files([
                ClipboardFile(path: "/tmp/report.pdf"),
                ClipboardFile(path: "/tmp/photo.jpg")
            ]))
        ]

        try persistence.save(expected, to: path)

        XCTAssertTrue(persistence.exists(at: path))
        XCTAssertEqual(try persistence.load(from: path), expected)
        let json = try String(contentsOfFile: path, encoding: .utf8)
        XCTAssertTrue(json.contains("\"version\" : 1"))
        XCTAssertTrue(json.contains("\"type\" : \"text\""))
        XCTAssertTrue(json.contains("\"type\" : \"files\""))
        XCTAssertEqual(
            try FileManager.default.attributesOfItem(atPath: path)[.posixPermissions] as? Int,
            0o600
        )

        try persistence.delete(at: path)
        XCTAssertFalse(persistence.exists(at: path))
    }

    func testFileItemsAreSearchableByNameExtensionAndPath() {
        let item = ClipboardItem(content: .files([
            ClipboardFile(path: "/Users/example/Documents/Quarterly Report.pdf"),
            ClipboardFile(path: "/Users/example/Desktop/mockup.sketch")
        ]))

        XCTAssertTrue(item.searchableText.localizedCaseInsensitiveContains("Quarterly Report.pdf"))
        XCTAssertTrue(item.searchableText.localizedCaseInsensitiveContains("mockup.sketch"))
        XCTAssertTrue(item.searchableText.localizedCaseInsensitiveContains("Documents"))
    }

    @MainActor
    func testPersistedLimitCannotBeLowerThanVisibleLimit() {
        let suiteName = "HistoryPersistenceSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(50, forKey: "maxHistoryItems")
        defaults.set(10, forKey: "maxPersistedHistoryItems")
        let settings = AppSettings(defaults: defaults)

        XCTAssertEqual(settings.maxPersistedHistoryItems, 50)
        settings.maxPersistedHistoryItems = 20
        XCTAssertEqual(settings.maxPersistedHistoryItems, 50)
        settings.maxHistoryItems = 75
        XCTAssertEqual(settings.maxPersistedHistoryItems, 75)
    }

    @MainActor
    func testDeletingAnItemUpdatesVisibleAndPersistedHistory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipboardStoreDeletionTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("history.json").path
        let suiteName = "ClipboardStoreDeletionSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "persistHistory")
        defaults.set(5, forKey: "maxHistoryItems")
        defaults.set(5, forKey: "maxPersistedHistoryItems")
        let settings = AppSettings(defaults: defaults)
        let persistence = HistoryPersistence()
        let store = ClipboardStore(settings: settings, persistence: persistence, historyFilePath: path)
        let first = ClipboardItem(content: .text("first"))
        let second = ClipboardItem(content: .text("second"))

        store.promote(first)
        store.promote(second)
        XCTAssertTrue(store.delete(first))

        XCTAssertEqual(store.items, [second])
        XCTAssertEqual(try persistence.load(from: path), [second])
        XCTAssertFalse(store.delete(first))
    }

    @MainActor
    func testStoreRestoresOnlyVisibleLimitAndDeletesOnlyTheFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipboardStorePersistenceTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("history.json").path
        let persistedItems = (1...5).reversed().map { ClipboardItem(content: .text("item \($0)")) }
        let persistence = HistoryPersistence()
        try persistence.save(persistedItems, to: path)
        XCTAssertEqual(try persistence.load(from: path).count, 5)

        var buffer = HistoryBuffer()
        buffer.replace(with: persistedItems, limit: 2)
        XCTAssertEqual(buffer.items.count, 2)

        let suiteName = "ClipboardStorePersistenceSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "persistHistory")
        defaults.set(2, forKey: "maxHistoryItems")
        defaults.set(5, forKey: "maxPersistedHistoryItems")
        let settings = AppSettings(defaults: defaults)
        XCTAssertTrue(settings.persistHistory)
        let store = ClipboardStore(settings: settings, persistence: persistence, historyFilePath: path)

        XCTAssertNil(store.persistenceError)
        XCTAssertEqual(store.items.map(\.searchableText), ["item 5", "item 4"])
        settings.maxHistoryItems = 4
        XCTAssertEqual(store.items.map(\.searchableText), ["item 5", "item 4", "item 3", "item 2"])

        store.promote(ClipboardItem(content: .text("new item")))
        XCTAssertEqual(try persistence.load(from: path).first?.searchableText, "new item")
        settings.persistHistory = false
        XCTAssertTrue(persistence.exists(at: path))
        store.deletePersistedHistory()
        XCTAssertEqual(store.items.map(\.searchableText), ["new item", "item 5", "item 4", "item 3"])
        XCTAssertFalse(persistence.exists(at: path))
    }
}
