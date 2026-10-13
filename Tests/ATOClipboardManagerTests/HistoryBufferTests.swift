import XCTest
@testable import ATOClipboardManager

final class HistoryBufferTests: XCTestCase {
    func testDuplicateMovesToFront() {
        var history = HistoryBuffer()
        let first = ClipboardItem(content: .text("first"))
        let second = ClipboardItem(content: .text("second"))
        history.insert(first, limit: 20)
        history.insert(second, limit: 20)
        history.insert(first, limit: 20)
        XCTAssertEqual(history.items.map(\.searchableText), ["first", "second"])
    }

    func testHistoryRespectsLimit() {
        var history = HistoryBuffer()
        for number in 0..<5 { history.insert(ClipboardItem(content: .text("\(number)")), limit: 3) }
        XCTAssertEqual(history.items.map(\.searchableText), ["4", "3", "2"])
    }

    func testHistoryLimitIsClamped() {
        XCTAssertEqual(AppSettings.clampHistoryLimit(0), 1)
        XCTAssertEqual(AppSettings.clampHistoryLimit(120), 100)
    }
}
