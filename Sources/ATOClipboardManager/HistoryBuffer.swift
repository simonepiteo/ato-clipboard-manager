import Foundation

struct HistoryBuffer {
    private(set) var items: [ClipboardItem] = []

    mutating func insert(_ item: ClipboardItem, limit: Int) {
        items.removeAll { $0 == item }
        items.insert(item, at: 0)
        trim(to: limit)
    }

    mutating func replace(with newItems: [ClipboardItem], limit: Int) {
        var seen = Set<ClipboardItem>()
        var uniqueItems: [ClipboardItem] = []
        let validLimit = max(limit, 1)
        for item in newItems where seen.insert(item).inserted {
            uniqueItems.append(item)
            if uniqueItems.count == validLimit { break }
        }
        items = uniqueItems
    }

    mutating func trim(to limit: Int) {
        items = Array(items.prefix(max(limit, 1)))
    }

    mutating func clear() {
        items.removeAll()
    }
}
