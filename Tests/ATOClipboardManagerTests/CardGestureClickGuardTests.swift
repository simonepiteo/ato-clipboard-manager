import XCTest
@testable import ATOClipboardManager

final class CardGestureClickGuardTests: XCTestCase {
    func testOrdinaryClicksPassThrough() {
        var guardState = CardGestureClickGuard()
        XCTAssertFalse(guardState.mouseDown(at: 100))
        XCTAssertFalse(guardState.mouseUp())
        XCTAssertFalse(guardState.suppressesActivation(at: 100 + CardGestureClickGuard.activationDelay))
    }

    func testPinchStartingAfterMouseDownPreventsCardActivation() {
        var guardState = CardGestureClickGuard()
        XCTAssertFalse(guardState.mouseDown(at: 100))
        guardState.beginGesture()
        // Deliver the matching mouseUp to reset the button's pressed appearance,
        // but reject its action while the pinch is in progress.
        XCTAssertFalse(guardState.mouseUp())
        XCTAssertTrue(guardState.suppressesActivation(at: 100 + CardGestureClickGuard.activationDelay))
        guardState.endGesture(at: 101)
        XCTAssertTrue(guardState.suppressesActivation(at: 101.1))
        XCTAssertFalse(guardState.suppressesActivation(at: 101.31))
    }

    func testMousePressDuringPinchSwallowsBothDownAndUp() {
        var guardState = CardGestureClickGuard()
        guardState.beginGesture()
        XCTAssertTrue(guardState.mouseDown(at: 100))
        guardState.endGesture(at: 101)
        XCTAssertTrue(guardState.mouseUp())
        XCTAssertFalse(guardState.mouseUp())
    }

    func testLiftingFingersDoesNotActivateCardButLaterClickWorks() {
        var guardState = CardGestureClickGuard()
        guardState.beginGesture()
        guardState.endGesture(at: 100)
        XCTAssertTrue(guardState.mouseDown(at: 100.1))
        XCTAssertTrue(guardState.mouseUp())
        XCTAssertFalse(guardState.mouseDown(at: 100.4))
        XCTAssertFalse(guardState.mouseUp())
    }

    func testClosingPopoverDuringGestureCannotLeaveClicksBlocked() {
        var guardState = CardGestureClickGuard()
        guardState.beginGesture()
        guardState.cancel(at: 100)
        XCTAssertFalse(guardState.isGesturing)
        XCTAssertFalse(guardState.suppressesActivation(at: 101))
    }
}
