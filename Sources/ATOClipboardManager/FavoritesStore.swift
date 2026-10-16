import Combine
import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    nonisolated static let defaultFilePath = "~/.ato/favorites.json"

    @Published private(set) var items: [ClipboardItem] = []
    @Published var persistenceError: String?

    private let persistence: HistoryPersistence
    private let filePath: String

    init(
        persistence: HistoryPersistence = HistoryPersistence(),
        filePath: String = FavoritesStore.defaultFilePath
    ) {
        self.persistence = persistence
        self.filePath = filePath
        restore()
    }

    func contains(_ item: ClipboardItem) -> Bool {
        items.contains(item)
    }

    func toggle(_ item: ClipboardItem) {
        toggle([item])
    }

    @discardableResult
    func toggle(_ selectedItems: [ClipboardItem]) -> Bool {
        guard !selectedItems.isEmpty else { return false }
        let allPinned = selectedItems.allSatisfy { contains($0) }
        return setPinned(!allPinned, for: selectedItems)
    }

    @discardableResult
    func setPinned(_ pinned: Bool, for selectedItems: [ClipboardItem]) -> Bool {
        let previous = items
        if pinned {
            var seen = Set(items)
            let additions = selectedItems.filter { seen.insert($0).inserted }
            items.insert(contentsOf: additions, at: 0)
        } else {
            let removed = Set(selectedItems)
            items.removeAll { removed.contains($0) }
        }
        guard items != previous else { return true }

        do {
            try persistence.save(items, to: filePath)
            persistenceError = nil
            return true
        } catch {
            items = previous
            persistenceError = error.localizedDescription
            return false
        }
    }

    private func restore() {
        do {
            let savedItems = try persistence.load(from: filePath)
            var seen = Set<ClipboardItem>()
            items = savedItems.filter { seen.insert($0).inserted }
            persistenceError = nil
        } catch {
            items = []
            persistenceError = error.localizedDescription
        }
    }
}
