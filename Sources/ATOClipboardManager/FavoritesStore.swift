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
        let previous = items
        if let index = items.firstIndex(of: item) {
            items.remove(at: index)
        } else {
            items.insert(item, at: 0)
        }

        do {
            try persistence.save(items, to: filePath)
            persistenceError = nil
        } catch {
            items = previous
            persistenceError = error.localizedDescription
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
