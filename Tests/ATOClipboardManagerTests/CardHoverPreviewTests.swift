import AppKit
import SwiftUI
import XCTest
@testable import ATOClipboardManager

final class CardHoverPreviewTests: XCTestCase {
    @MainActor
    func testZoomPreviewRendersCardContentInsteadOfAnEmptySurface() throws {
        let image = NSImage(size: NSSize(width: 30, height: 30), flipped: false) { rect in
            NSColor.red.setFill()
            rect.fill()
            return true
        }
        let imageData = try XCTUnwrap(image.tiffRepresentation)
        let contents: [ClipboardContent] = [
            .text("VISIBLE CARD CONTENT"),
            .image(imageData),
            .files([ClipboardFile(path: "/tmp/Preview document.txt")])
        ]

        for content in contents {
            for width: CGFloat in [100, 330] {
                let card = makeCard(content, width: width)
                let bitmap = try render(card, width: width, scale: 1.8)

                // Ignore the border: an empty card has only a uniform light interior.
                var contentPixels = 0
                for y in 16..<(bitmap.pixelsHigh - 16) {
                    for x in 16..<(bitmap.pixelsWide - 16) {
                        let color = try XCTUnwrap(bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                        if min(color.redComponent, color.greenComponent, color.blueComponent) < 0.5 {
                            contentPixels += 1
                        }
                    }
                }
                XCTAssertGreaterThan(contentPixels, 20, "Preview must contain text, an image, or a file icon (width: \(width)).")
            }
        }
    }

    @MainActor
    func testTextRevealsMoreLinesWithoutIncreasingGlyphHeight() throws {
        for width: CGFloat in [100, 330] {
            let card = makeCard(.text(Array(repeating: "MMMM", count: 20).joined(separator: "\n")), width: width)
            let compact = try render(card, width: width, scale: 1)
            let expanded = try render(card, width: width, scale: 1.8, artifact: "text-\(Int(width))")
            let compactLines = try inkBands(compact)
            let expandedLines = try inkBands(expanded)
            XCTAssertGreaterThan(expandedLines.count, compactLines.count)
            XCTAssertEqual(try XCTUnwrap(expandedLines.first), try XCTUnwrap(compactLines.first), accuracy: 1)
        }
    }

    @MainActor
    func testFilePreviewRevealsMoreRowsWhenExpanded() throws {
        let files = (1...10).map { ClipboardFile(path: "/Users/Example/Documents/Document \($0).txt") }
        for width: CGFloat in [100, 330] {
            let card = makeCard(.files(files), width: width)
            let compact = try render(card, width: width, scale: 1)
            let expanded = try render(card, width: width, scale: 1.8, artifact: "files-\(Int(width))")
            XCTAssertGreaterThan(try inkBands(expanded).count, try inkBands(compact).count)
        }
    }

    @MainActor
    func testImageZoomKeepsShortcutPinAndSelectionGlyphsAtTheirOriginalSize() throws {
        let image = NSImage(size: NSSize(width: 30, height: 30), flipped: false) { rect in
            NSColor.red.setFill()
            rect.fill()
            return true
        }
        let content = ClipboardContent.image(try XCTUnwrap(image.tiffRepresentation))
        for width: CGFloat in [100, 330] {
            let cards = [
                makeCard(content, width: width, shortcut: "⌘9"),
                makeCard(content, width: width, pin: true),
                makeCard(content, width: width, selection: true)
            ]
            for (index, card) in cards.enumerated() {
                let compact = try render(card, width: width, scale: 1)
                let expanded = try render(card, width: width, scale: 1.8, artifact: "image-badge-\(index)-\(Int(width))")
                let isGlyph: (NSColor) -> Bool = { color in
                    index == 2
                        ? color.blueComponent - color.redComponent > 0.6 && color.blueComponent - color.greenComponent > 0.3
                        : min(color.redComponent, color.greenComponent, color.blueComponent) > 0.95
                }
                let originalGlyph = try XCTUnwrap(pixelBounds(compact, matching: isGlyph))
                let expandedGlyph = try XCTUnwrap(pixelBounds(expanded, matching: isGlyph))
                XCTAssertEqual(originalGlyph.width, expandedGlyph.width, accuracy: 1)
                XCTAssertEqual(originalGlyph.height, expandedGlyph.height, accuracy: 1)

                let isImage: (NSColor) -> Bool = { $0.redComponent > 0.8 && $0.greenComponent < 0.2 && $0.blueComponent < 0.2 }
                let originalImage = try XCTUnwrap(pixelBounds(compact, matching: isImage))
                let expandedImage = try XCTUnwrap(pixelBounds(expanded, matching: isImage))
                XCTAssertGreaterThan(expandedImage.width, originalImage.width * 1.5)
                XCTAssertGreaterThan(expandedImage.height, originalImage.height * 1.5)
            }
        }
    }

    private func pixelBounds(_ bitmap: NSBitmapImageRep, matching predicate: (NSColor) -> Bool) throws -> NSRect? {
        var minX = bitmap.pixelsWide
        var minY = bitmap.pixelsHigh
        var maxX = -1
        var maxY = -1
        // Exclude the selection-colored border when measuring the selection glyph.
        for y in 3..<(bitmap.pixelsHigh - 3) {
            for x in 3..<(bitmap.pixelsWide - 3) {
                let color = try XCTUnwrap(bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                if predicate(color) {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        return NSRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    private func makeCard(
        _ content: ClipboardContent, width: CGFloat, shortcut: String? = nil,
        selection: Bool = false, pin: Bool = false
    ) -> ClipboardCard {
        ClipboardCard(
            item: ClipboardItem(content: content), shortcut: shortcut, isList: width == 330,
            language: .english, isKeyboardSelected: false, isSelectionMode: selection,
            isBatchSelected: selection, selectForBatch: {}, showsFavoriteIndicator: pin,
            isFavorite: false, toggleFavorite: {}, favoriteActionTitle: "",
            deleteFromHistory: {}, deleteActionTitle: "", action: {}
        )
    }

    @MainActor
    private func render(_ card: ClipboardCard, width: CGFloat, scale: CGFloat, artifact: String? = nil) throws -> NSBitmapImageRep {
        let preview = CardHoverZoomPreview(preview: card.hoverPreview)
            .frame(width: width * scale, height: 98 * scale)
            .environment(\.colorScheme, .light)
            .foregroundStyle(.black)
            .accentColor(.blue)
        let renderer = ImageRenderer(content: preview)
        let bitmap = NSBitmapImageRep(cgImage: try XCTUnwrap(renderer.cgImage))
        if let artifact, let directory = ProcessInfo.processInfo.environment["ATO_PREVIEW_ARTIFACTS"] {
            let url = URL(fileURLWithPath: directory, isDirectory: true)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: url.appendingPathComponent("\(artifact).png"))
        }
        return bitmap
    }

    /// Count horizontal bands of rendered ink, ignoring the card border.
    private func inkBands(_ bitmap: NSBitmapImageRep) throws -> [Int] {
        var bands: [Int] = []
        var height = 0
        for y in 8..<(bitmap.pixelsHigh - 8) {
            var hasInk = false
            for x in 12..<(bitmap.pixelsWide - 12) {
                let color = try XCTUnwrap(bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                if min(color.redComponent, color.greenComponent, color.blueComponent) < 0.5 {
                    hasInk = true
                    break
                }
            }
            if hasInk {
                height += 1
            } else if height > 0 {
                bands.append(height)
                height = 0
            }
        }
        if height > 0 { bands.append(height) }
        return bands
    }
}
