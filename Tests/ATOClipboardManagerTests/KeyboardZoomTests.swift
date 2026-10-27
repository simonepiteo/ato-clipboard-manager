import XCTest
@testable import ATOClipboardManager

final class KeyboardZoomTests: XCTestCase {
    @MainActor
    func testNavigationKeepsZoomOnLatestTargetAndEscapeStopsIt() {
        let controller = CardHoverZoomController()
        defer { controller.cancel(animated: false) }
        let first = UUID()
        let second = UUID()
        let third = UUID()
        controller.toggleKeyboardZoom(itemID: first)
        XCTAssertEqual(controller.keyboardZoomItemID, first)
        controller.followKeyboardSelection(second)
        controller.followKeyboardSelection(third)
        XCTAssertEqual(controller.keyboardZoomItemID, third)

        // The target is pending while the lazy grid scrolls it into view.
        XCTAssertTrue(controller.dismissZoomForEscape())
        XCTAssertNil(controller.keyboardZoomItemID)
        XCTAssertFalse(controller.dismissZoomForEscape(), "The next Escape may exit selection or close the popover.")
        controller.followKeyboardSelection(first)
        XCTAssertNil(controller.keyboardZoomItemID, "Arrow navigation must not reopen zoom after Escape.")
    }

    @MainActor
    func testShortcutTogglesAndClearingSelectionCancelsPendingZoom() {
        let controller = CardHoverZoomController()
        defer { controller.cancel(animated: false) }
        let item = UUID()
        controller.toggleKeyboardZoom(itemID: item)
        controller.toggleKeyboardZoom(itemID: item)
        XCTAssertNil(controller.keyboardZoomItemID)
        controller.toggleKeyboardZoom(itemID: item)
        controller.followKeyboardSelection(nil)
        XCTAssertNil(controller.keyboardZoomItemID)
    }
}
