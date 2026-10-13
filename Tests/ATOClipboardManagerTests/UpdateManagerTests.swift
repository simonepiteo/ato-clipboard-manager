import XCTest
@testable import ATOClipboardManager

final class UpdateManagerTests: XCTestCase {
    func testSemanticVersionComparison() {
        XCTAssertLessThan(VersionNumber("0.3.9"), VersionNumber("0.4.0"))
        XCTAssertLessThan(VersionNumber("v1.9.0"), VersionNumber("1.10.0"))
        XCTAssertEqual(VersionNumber("2.1"), VersionNumber("2.1.0"))
    }

    func testVersionTagsAreNormalized() {
        XCTAssertEqual(VersionNumber.normalized(" v1.2.3 "), "1.2.3")
    }
}
