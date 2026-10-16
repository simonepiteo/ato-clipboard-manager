import XCTest
@testable import ATOClipboardManager

final class ReleasePaginationTests: XCTestCase {
    func testUpToTenReleasesUseOnePage() {
        for count in [0, 1, 9, 10] {
            let page = ReleasePagination(itemCount: count, pageIndex: 0)
            XCTAssertEqual(page.pageCount, 1)
            XCTAssertEqual(page.itemRange, 0..<count)
        }
    }

    func testPagesContainEveryReleaseExactlyOnce() {
        for count in [11, 20, 21, 30] {
            let pageCount = ReleasePagination(itemCount: count, pageIndex: 0).pageCount
            let pages = (0..<pageCount).map { ReleasePagination(itemCount: count, pageIndex: $0) }

            XCTAssertEqual(pages.flatMap { Array($0.itemRange) }, Array(0..<count))
            XCTAssertTrue(pages.dropLast().allSatisfy { $0.itemRange.count == 10 })
            XCTAssertTrue((1...10).contains(pages.last!.itemRange.count))
        }
    }

    func testPageIsClampedWhenReleasesShrinkOrBecomeEmpty() {
        let smaller = ReleasePagination(itemCount: 11, pageIndex: 2)
        XCTAssertEqual(smaller.pageIndex, 1)
        XCTAssertEqual(smaller.itemRange, 10..<11)

        let empty = ReleasePagination(itemCount: 0, pageIndex: 2)
        XCTAssertEqual(empty.pageIndex, 0)
        XCTAssertEqual(empty.itemRange, 0..<0)

        XCTAssertEqual(ReleasePagination(itemCount: 20, pageIndex: -1).pageIndex, 0)
    }
}
