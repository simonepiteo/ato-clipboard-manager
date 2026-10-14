import AppKit
import SwiftUI

struct DraggableApplicationIcon: NSViewRepresentable {
    let accessibilityLabel: String
    var onSuccessfulDrop: () -> Void = {}

    func makeNSView(context: Context) -> DraggableApplicationImageView {
        DraggableApplicationImageView(
            applicationURL: Self.applicationURL,
            accessibilityLabel: accessibilityLabel,
            onSuccessfulDrop: onSuccessfulDrop
        )
    }

    func updateNSView(_ view: DraggableApplicationImageView, context: Context) {
        view.setAccessibilityLabel(accessibilityLabel)
        view.onSuccessfulDrop = onSuccessfulDrop
    }

    private static var applicationURL: URL? {
        var candidate = Bundle.main.bundleURL.standardizedFileURL

        while candidate.path != "/" {
            if candidate.pathExtension.lowercased() == "app" {
                return candidate
            }
            candidate.deleteLastPathComponent()
        }

        return nil
    }
}

final class DraggableApplicationImageView: NSImageView, NSDraggingSource {
    private let applicationURL: URL?
    private var startedDragging = false
    var onSuccessfulDrop: () -> Void

    init(applicationURL: URL?, accessibilityLabel: String, onSuccessfulDrop: @escaping () -> Void) {
        self.applicationURL = applicationURL
        self.onSuccessfulDrop = onSuccessfulDrop
        super.init(frame: .zero)

        image = applicationURL.map { NSWorkspace.shared.icon(forFile: $0.path) }
            ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)
        imageScaling = .scaleProportionallyUpOrDown
        isEditable = false
        isEnabled = applicationURL != nil
        toolTip = accessibilityLabel
        setAccessibilityElement(true)
        setAccessibilityRole(.image)
        setAccessibilityLabel(accessibilityLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: applicationURL == nil ? .arrow : .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        startedDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !startedDragging, let applicationURL else { return }
        startedDragging = true

        let item = NSDraggingItem(pasteboardWriter: applicationURL as NSURL)
        item.setDraggingFrame(bounds, contents: image)
        beginDraggingSession(with: [item], event: event, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        startedDragging = false
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        startedDragging = false
        if operation != [] {
            onSuccessfulDrop()
        }
    }
}
