import AppKit
import XCTest
@testable import ATOClipboardManager

final class CardMagnificationIntentTests: XCTestCase {
    func testOutwardPinchAccumulatesAndOpensOnlyOnce() {
        var intent = CardMagnificationIntent()
        XCTAssertFalse(intent.update(delta: 0.02, phase: .began))
        XCTAssertFalse(intent.update(delta: 0.02, phase: .changed))
        XCTAssertTrue(intent.update(delta: 0.02, phase: .changed))
        XCTAssertFalse(intent.update(delta: 0.1, phase: .changed))
        XCTAssertFalse(intent.update(delta: 0, phase: .ended))
        XCTAssertTrue(intent.update(delta: 0.06, phase: .began))
    }

    func testInwardPinchAndCancelledGestureDoNotOpen() {
        var intent = CardMagnificationIntent()
        XCTAssertFalse(intent.update(delta: -0.2, phase: .began))
        XCTAssertFalse(intent.update(delta: -0.1, phase: .ended))
        XCTAssertFalse(intent.update(delta: 0.03, phase: .began))
        XCTAssertFalse(intent.update(delta: 0.03, phase: .cancelled))
        XCTAssertFalse(intent.update(delta: 0.02, phase: .began))
    }
}
