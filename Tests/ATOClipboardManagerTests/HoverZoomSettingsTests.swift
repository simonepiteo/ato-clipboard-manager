import XCTest
@testable import ATOClipboardManager

final class HoverZoomSettingsTests: XCTestCase {
    @MainActor
    func testDefaultsPersistenceAndReset() {
        let suiteName = "HoverZoomSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = AppSettings(defaults: defaults)

        XCTAssertTrue(settings.hoverZoomEnabled)
        XCTAssertEqual(settings.hoverZoomDelay, 3)
        settings.hoverZoomEnabled = false
        settings.hoverZoomDelay = 8

        let restored = AppSettings(defaults: defaults)
        XCTAssertFalse(restored.hoverZoomEnabled)
        XCTAssertEqual(restored.hoverZoomDelay, 8)
        restored.hoverZoomEnabled = true
        XCTAssertEqual(restored.hoverZoomDelay, 8, "Toggling the feature must preserve the chosen delay.")

        restored.reset()
        let reset = AppSettings(defaults: defaults)
        XCTAssertTrue(reset.hoverZoomEnabled)
        XCTAssertEqual(reset.hoverZoomDelay, 3)
    }

    @MainActor
    func testOutOfRangeDelayIsClampedInMemoryAndOnDisk() {
        let suiteName = "HoverZoomSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(100, forKey: "hoverZoomDelay")
        let settings = AppSettings(defaults: defaults)
        XCTAssertEqual(settings.hoverZoomDelay, 30)

        settings.hoverZoomDelay = 0
        XCTAssertEqual(settings.hoverZoomDelay, 1)
        XCTAssertEqual(AppSettings(defaults: defaults).hoverZoomDelay, 1)
        settings.hoverZoomDelay = 100
        XCTAssertEqual(settings.hoverZoomDelay, 30)
        XCTAssertEqual(AppSettings(defaults: defaults).hoverZoomDelay, 30)
    }
}
