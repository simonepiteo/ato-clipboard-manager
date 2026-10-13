import AppKit
import Combine
import Foundation

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var hasPersistedHistory = false
    @Published var persistenceError: String?

    private var buffer = HistoryBuffer()
    private var persistedBuffer = HistoryBuffer()
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var ignoredChangeCount: Int?
    private let settings: AppSettings
    private let persistence: HistoryPersistence
    private let historyFilePath: String
    private var cancellables = Set<AnyCancellable>()

    init(
        settings: AppSettings,
        persistence: HistoryPersistence = HistoryPersistence(),
        historyFilePath: String = AppSettings.defaultHistoryFilePath
    ) {
        self.settings = settings
        self.persistence = persistence
        self.historyFilePath = historyFilePath

        if settings.persistHistory {
            restorePersistedHistory(includingCurrentItems: false)
        } else {
            refreshPersistedHistoryAvailability()
        }
        observeSettings()
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
    func delete(_ item: ClipboardItem) -> Bool {
        let previousBuffer = buffer
        let previousPersistedBuffer = persistedBuffer
        let removedFromVisibleHistory = buffer.remove(item)

        guard settings.persistHistory else {
            items = buffer.items
            return removedFromVisibleHistory
        }

        let removedFromSavedHistory = persistedBuffer.remove(item)
        guard removedFromVisibleHistory || removedFromSavedHistory else { return false }

        do {
            try persistence.save(persistedBuffer.items, to: historyFilePath)
            items = buffer.items
            hasPersistedHistory = true
            persistenceError = nil
            return true
        } catch {
            buffer = previousBuffer
            persistedBuffer = previousPersistedBuffer
            items = buffer.items
            persistenceError = error.localizedDescription
            refreshPersistedHistoryAvailability()
            return false
        }
    }

    func deletePersistedHistory() {
        do {
            try persistence.delete(at: historyFilePath)
            persistedBuffer.clear()
            hasPersistedHistory = false
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
            refreshPersistedHistoryAvailability()
        }
    }

    @discardableResult
    func copy(_ item: ClipboardItem, moveToFront: Bool = true) -> Bool {
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

        if moveToFront {
            promote(item)
        }
        return true
    }

    func promote(_ item: ClipboardItem) {
        record(item)
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
        record(item)
    }

    private func record(_ item: ClipboardItem) {
        buffer.insert(item, limit: settings.maxHistoryItems)
        items = buffer.items

        guard settings.persistHistory else { return }
        persistedBuffer.insert(item, limit: settings.maxPersistedHistoryItems)
        savePersistedHistory()
    }

    private func observeSettings() {
        settings.$persistHistory
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    self.restorePersistedHistory(includingCurrentItems: true)
                } else {
                    self.refreshPersistedHistoryAvailability()
                }
            }
            .store(in: &cancellables)

        settings.$maxHistoryItems
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] limit in
                guard let self else { return }
                if self.settings.persistHistory {
                    self.buffer.replace(with: self.persistedBuffer.items, limit: limit)
                } else {
                    self.buffer.trim(to: limit)
                }
                self.items = self.buffer.items
            }
            .store(in: &cancellables)

        settings.$maxPersistedHistoryItems
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] limit in
                guard let self, self.settings.persistHistory else { return }
                let validLimit = AppSettings.clampPersistedHistoryLimit(
                    limit,
                    minimum: self.settings.maxHistoryItems
                )
                self.persistedBuffer.trim(to: validLimit)
                self.savePersistedHistory()
            }
            .store(in: &cancellables)

    }

    private func restorePersistedHistory(includingCurrentItems: Bool) {
        do {
            let persistedItems = try persistence.load(from: historyFilePath)
            let combinedItems = includingCurrentItems ? buffer.items + persistedItems : persistedItems
            persistedBuffer.replace(with: combinedItems, limit: settings.maxPersistedHistoryItems)
            buffer.replace(with: persistedBuffer.items, limit: settings.maxHistoryItems)
            items = buffer.items
            persistenceError = nil
            savePersistedHistory()
        } catch {
            persistenceError = error.localizedDescription
            refreshPersistedHistoryAvailability()
        }
    }

    private func savePersistedHistory() {
        do {
            try persistence.save(persistedBuffer.items, to: historyFilePath)
            hasPersistedHistory = true
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
            refreshPersistedHistoryAvailability()
        }
    }

    private func refreshPersistedHistoryAvailability() {
        hasPersistedHistory = persistence.exists(at: historyFilePath)
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
