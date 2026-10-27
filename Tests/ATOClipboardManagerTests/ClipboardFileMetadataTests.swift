import AppKit
import SwiftUI
import XCTest
@testable import ATOClipboardManager

final class ClipboardFileMetadataTests: XCTestCase {
    func testReadsActualFileSizeAndModificationDate() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("example.txt")
        try Data(repeating: 65, count: 2048).write(to: url)
        let metadata = ClipboardFileMetadata.read(ClipboardFile(url: url))
        XCTAssertEqual(metadata.byteCount, 2048)
        XCTAssertNotNil(metadata.modifiedAt)
        XCTAssertFalse(metadata.isDirectory)

        try Data().write(to: url)
        XCTAssertEqual(ClipboardFileMetadata.read(ClipboardFile(url: url)).byteCount, 0)
    }

    func testFolderDoesNotUseDirectoryEntrySizeAsContentSize() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let metadata = ClipboardFileMetadata.read(ClipboardFile(url: directory))
        XCTAssertTrue(metadata.isDirectory)
        XCTAssertNil(metadata.byteCount)
    }

    func testMissingFileHasNoInventedSizeOrDate() {
        let file = ClipboardFile(url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let metadata = ClipboardFileMetadata.read(file)
        XCTAssertNil(metadata.byteCount)
        XCTAssertNil(metadata.modifiedAt)
    }

    @MainActor
    func testSingleFileDetailsRenderAtGridAndListSizes() throws {
        let icon = try XCTUnwrap(NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil))
        for width: CGFloat in [180, 594] {
            for language: AppLanguage in [.english, .italian] {
                let content = SingleFileDetailsContent(
                    file: ClipboardFile(path: "/Users/Example/Documents/Quarterly report.pdf"),
                    language: language, icon: icon,
                    metadata: ClipboardFileMetadata(
                        byteCount: 145_000, modifiedAt: Date(timeIntervalSince1970: 1_793_001_600),
                        kind: "PDF", isDirectory: false
                    )
                )
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 19)
                .frame(width: width, height: 176)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, .light)
                let renderer = ImageRenderer(content: content)
                let bitmap = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
                if let directory = ProcessInfo.processInfo.environment["ATO_PREVIEW_ARTIFACTS"] {
                    let url = URL(fileURLWithPath: directory, isDirectory: true)
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(
                        to: url.appendingPathComponent("single-file-\(Int(width))-\(language.rawValue).png")
                    )
                }
            }
        }
    }
}
