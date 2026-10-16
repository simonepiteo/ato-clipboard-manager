import Foundation

struct ClipboardSelection {
    private(set) var isActive = false
    private(set) var itemIDs = Set<UUID>()

    mutating func begin(with itemID: UUID) {
        isActive = true
        itemIDs.insert(itemID)
    }

    mutating func toggle(_ itemID: UUID) {
        guard isActive else { return }
        if !itemIDs.insert(itemID).inserted { itemIDs.remove(itemID) }
    }

    mutating func toggleAll(_ visibleIDs: Set<UUID>) {
        guard isActive, !visibleIDs.isEmpty else { return }
        if visibleIDs.isSubset(of: itemIDs) {
            itemIDs.subtract(visibleIDs)
        } else {
            itemIDs.formUnion(visibleIDs)
        }
    }

    mutating func retain(_ visibleIDs: Set<UUID>) {
        itemIDs.formIntersection(visibleIDs)
    }

    mutating func end() {
        isActive = false
        itemIDs.removeAll()
    }
}
