import AppKit
import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var settings: AppSettings
    @State private var searchText = ""

    let select: (ClipboardItem, Bool) -> Void
    let openSettings: () -> Void
    let quit: () -> Void

    private var filteredItems: [ClipboardItem] {
        guard !searchText.isEmpty else { return store.items }
        return store.items.filter { $0.searchableText.localizedCaseInsensitiveContains(searchText) }
    }

    private var columns: [GridItem] {
        settings.displayMode == .grid
            ? [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible())]
            : [GridItem(.flexible())]
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            history
            Divider()
            footerActions
        }
        .frame(width: 350, height: 436)
        .background(.ultraThinMaterial)
        .onReceive(NotificationCenter.default.publisher(for: .selectClipboardHistoryItem)) { notification in
            guard let index = notification.userInfo?["index"] as? Int,
                  filteredItems.indices.contains(index)
            else { return }
            select(filteredItems[index], settings.automaticPasteShortcut)
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(Localizer.text(.search, language: settings.language), text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .padding(10)
    }

    private var history: some View {
        ScrollView {
            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clipboard").font(.system(size: 32)).foregroundStyle(.secondary)
                    Text(Localizer.text(.emptyHistory, language: settings.language))
                        .multilineTextAlignment(.center).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 285)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardCard(item: item, shortcut: index < 9 ? index + 1 : nil, isList: settings.displayMode == .list) {
                            select(item, settings.automaticPaste)
                        }
                    }
                }
                .padding(10)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color.black.opacity(0.08))
    }

    private var footerActions: some View {
        VStack(spacing: 0) {
            Button(action: store.clear) {
                footerLabel(Localizer.text(.clearHistory, language: settings.language))
            }
            .buttonStyle(.borderless)

            Button(action: openSettings) {
                footerLabel(Localizer.text(.settings, language: settings.language), shortcut: "⌘⌥S")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("s", modifiers: [.command, .option])

            Divider()
                .padding(.horizontal, 8)

            Button(role: .destructive, action: quit) {
                footerLabel(Localizer.text(.quit, language: settings.language), shortcut: "⌘Q")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.vertical, 4)
    }

    private func footerLabel(_ title: String, shortcut: String? = nil) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let shortcut {
                Text(shortcut)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
    }
}

private struct ClipboardCard: View {
    let item: ClipboardItem
    let shortcut: Int?
    let isList: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    switch item.content {
                    case let .text(text):
                        Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                            .lineLimit(isList ? 4 : 6).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    case let .image(data):
                        if let image = NSImage(data: data) {
                            Image(nsImage: image).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .padding(6)
                if let shortcut {
                    Text("⌘\(shortcut)").font(.caption2).padding(.horizontal, 5).padding(.vertical, 2)
                        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 4)).foregroundStyle(.white)
                        .padding(5)
                }
            }
            .frame(height: 98)
            .contentShape(Rectangle())
        }
        .buttonStyle(CardButtonStyle())
    }
}

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.accentColor.opacity(0.35) : Color.black.opacity(0.10))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(configuration.isPressed ? Color.accentColor : Color.secondary.opacity(0.35)))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
