import XCTest
@testable import ATOClipboardManager

final class CardHoverIntentTests: XCTestCase {
    func testRequiresThreeStationarySeconds() {
        var intent = CardHoverIntent()
        XCTAssertFalse(intent.isReady(at: 100))
        intent.move(to: NSPoint(x: 10, y: 20), at: 100)
        XCTAssertFalse(intent.isReady(at: 102.99))
        XCTAssertTrue(intent.isReady(at: 103))
    }

    func testMovementRestartsDelayButRepeatedPositionDoesNot() {
        var intent = CardHoverIntent()
        intent.move(to: NSPoint(x: 10, y: 20), at: 100)
        intent.move(to: NSPoint(x: 10, y: 20), at: 102)
        XCTAssertTrue(intent.isReady(at: 103))
        intent.move(to: NSPoint(x: 11, y: 20), at: 103)
        XCTAssertFalse(intent.isReady(at: 105.99))
        XCTAssertTrue(intent.isReady(at: 106))
    }

    func testZoomKeepsCenterAndScalesBothAxesEqually() {
        for width: CGFloat in [100, 330] {
            let source = NSRect(x: 700, y: 400, width: width, height: 98)
            let expanded = CardHoverIntent.expandedFrame(from: source)
            XCTAssertEqual(expanded.midX, source.midX, accuracy: 0.001)
            XCTAssertEqual(expanded.midY, source.midY, accuracy: 0.001)
            XCTAssertEqual(expanded.width / source.width, 1.8, accuracy: 0.001)
            XCTAssertEqual(expanded.height / source.height, 1.8, accuracy: 0.001)
        }
    }

    func testUsesConfiguredDelayAndRestartsItAfterMovement() {
        for delay: TimeInterval in [1, 7, 30] {
            var intent = CardHoverIntent(delay: delay)
            intent.move(to: NSPoint(x: 10, y: 20), at: 100)
            XCTAssertFalse(intent.isReady(at: 100 + delay - 0.01))
            XCTAssertTrue(intent.isReady(at: 100 + delay))
            intent.move(to: NSPoint(x: 11, y: 20), at: 200)
            XCTAssertFalse(intent.isReady(at: 200 + delay - 0.01))
            XCTAssertTrue(intent.isReady(at: 200 + delay))
        }
    }
}
