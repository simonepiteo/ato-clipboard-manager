import Foundation

struct HistoryBuffer {
    private(set) var items: [ClipboardItem] = []

    mutating func insert(_ item: ClipboardItem, limit: Int) {
        items.removeAll { $0 == item }
        items.insert(item, at: 0)
        items = Array(items.prefix(AppSettings.clampHistoryLimit(limit)))
    }

    mutating func clear() {
        items.removeAll()
    }
}
