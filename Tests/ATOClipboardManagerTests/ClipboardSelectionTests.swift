import Foundation
import XCTest
@testable import ATOClipboardManager

final class ClipboardSelectionTests: XCTestCase {
    func testSelectionModeCanStartWithoutFocusingOrSelectingAnyCard() {
        var selection = ClipboardSelection()
        selection.begin()
        XCTAssertTrue(selection.isActive)
        XCTAssertTrue(selection.itemIDs.isEmpty)
        selection.end()
        XCTAssertFalse(selection.isActive)
        XCTAssertTrue(selection.itemIDs.isEmpty)
    }

    func testSelectionMustBeActivatedAndStaysActiveWhenEmpty() {
        let first = UUID()
        let second = UUID()
        var selection = ClipboardSelection()
        selection.toggle(first)
        XCTAssertTrue(selection.itemIDs.isEmpty)

        selection.begin(with: first)
        selection.toggle(second)
        XCTAssertEqual(selection.itemIDs, [first, second])
        selection.toggle(first)
        selection.toggle(second)
        XCTAssertTrue(selection.isActive)
        XCTAssertTrue(selection.itemIDs.isEmpty)

        selection.begin(with: first)
        selection.end()
        XCTAssertFalse(selection.isActive)
        XCTAssertTrue(selection.itemIDs.isEmpty)
    }

    func testSelectAllAndDeselectAllRespectVisibleItems() {
        let first = UUID()
        let second = UUID()
        let visible: Set<UUID> = [first, second]
        var selection = ClipboardSelection()
        selection.begin(with: first)
        selection.toggleAll(visible)
        XCTAssertEqual(selection.itemIDs, visible)
        selection.toggleAll(visible)
        XCTAssertTrue(selection.itemIDs.isEmpty)
        XCTAssertTrue(selection.isActive)
    }

    func testSearchSectionChangesAndDeletionPruneUnavailableSelections() {
        let first = UUID()
        let second = UUID()
        var selection = ClipboardSelection()
        selection.begin(with: first)
        selection.toggle(second)
        selection.retain([second])
        XCTAssertEqual(selection.itemIDs, [second])
        selection.retain([])
        XCTAssertTrue(selection.itemIDs.isEmpty)
        XCTAssertTrue(selection.isActive)
    }
}
