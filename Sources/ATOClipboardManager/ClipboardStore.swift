import AppKit
import Foundation

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    private var buffer = HistoryBuffer()
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var ignoredChangeCount: Int?
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func start() {
        guard timer == nil else { return }
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.readPasteboardIfChanged() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func clear() {
        buffer.clear()
        items = buffer.items
    }

    @discardableResult
    func copy(_ item: ClipboardItem) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let didWrite: Bool
        switch item.content {
        case let .text(value):
            didWrite = pasteboard.setString(value, forType: .string)
        case let .image(data):
            if let image = NSImage(data: data) {
                didWrite = pasteboard.writeObjects([image])
            } else {
                didWrite = false
            }
        }

        guard didWrite else { return false }
        ignoredChangeCount = pasteboard.changeCount
        lastChangeCount = pasteboard.changeCount

        buffer.insert(item, limit: settings.maxHistoryItems)
        items = buffer.items
        return true
    }

    private func readPasteboardIfChanged() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if ignoredChangeCount == pasteboard.changeCount {
            ignoredChangeCount = nil
            return
        }

        let item: ClipboardItem?
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            item = ClipboardItem(content: .text(text))
        } else if let data = imageData(from: pasteboard) {
            item = ClipboardItem(content: .image(data))
        } else {
            item = nil
        }

        guard let item else { return }
        buffer.insert(item, limit: settings.maxHistoryItems)
        items = buffer.items
    }

    private func imageData(from pasteboard: NSPasteboard) -> Data? {
        if let png = pasteboard.data(forType: .png) { return png }
        guard let image = NSImage(pasteboard: pasteboard),
              let tiff = image.tiffRepresentation,
              let representation = NSBitmapImageRep(data: tiff)
        else { return nil }
        return representation.representation(using: .png, properties: [:])
    }
}
