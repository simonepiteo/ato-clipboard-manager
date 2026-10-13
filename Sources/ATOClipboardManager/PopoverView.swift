import AppKit
import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: ClipboardStore
    @ObservedObject var settings: AppSettings
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var shortcutSettings: ShortcutSettings
    @ObservedObject var favoritesStore: FavoritesStore
    @State private var searchText = ""
    @State private var dismissedUpdateVersion: String?
    @State private var selectedSection: ClipboardSection = .history

    let select: (ClipboardItem, Bool, Bool) -> Void
    let openSettings: () -> Void
    let quit: () -> Void

    private var filteredItems: [ClipboardItem] {
        let items = items(for: selectedSection)
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.searchableText.localizedCaseInsensitiveContains(searchText) }
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
            if let release = visibleUpdate {
                updateBanner(release)
                Divider()
            }
            ZStack(alignment: .bottom) {
                history
                sectionSwitcher
                    .padding(.bottom, 12)
            }
            Divider()
            footerActions
        }
        .frame(width: 350, height: 500)
        .background(.ultraThinMaterial)
        .onReceive(NotificationCenter.default.publisher(for: .selectClipboardHistoryItem)) { notification in
            guard let index = notification.userInfo?["index"] as? Int,
                  filteredItems.indices.contains(index)
            else { return }
            select(filteredItems[index], settings.automaticPasteShortcut, false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchClipboardSection)) { notification in
            guard let rawValue = notification.userInfo?["section"] as? String,
                  let section = ClipboardSection(rawValue: rawValue)
            else { return }
            selectedSection = section
        }
        .alert(
            Localizer.text(.favoritesPersistenceError, language: settings.language),
            isPresented: Binding(
                get: { favoritesStore.persistenceError != nil },
                set: { if !$0 { favoritesStore.persistenceError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(favoritesStore.persistenceError ?? "")
        }
    }

    private func items(for section: ClipboardSection) -> [ClipboardItem] {
        section == .history ? store.items : favoritesStore.items
    }

    private var visibleUpdate: AppRelease? {
        guard let release = updateManager.availableUpdate,
              dismissedUpdateVersion != release.version else { return nil }
        return release
    }

    private func updateBanner(_ release: AppRelease) -> some View {
        HStack(spacing: 9) {
            if updateManager.isInstalling {
                ProgressView()
                    .controlSize(.small)
                Text(Localizer.text(.installingUpdate, language: settings.language))
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(Color.accentColor)

                if let errorMessage = updateManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .help(errorMessage)
                } else {
                    Text(String(
                        format: Localizer.text(.updateAvailable, language: settings.language),
                        release.version
                    ))
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if !updateManager.isInstalling {
                Button(Localizer.text(.updateNow, language: settings.language)) {
                    Task { await updateManager.install(release) }
                }
                .buttonStyle(.borderedProminent)
            }

            Button {
                dismissedUpdateVersion = release.version
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(Localizer.text(.later, language: settings.language))
            .disabled(updateManager.isInstalling)
        }
        .controlSize(.small)
        .padding(10)
        .background(Color.accentColor.opacity(0.08))
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
                    Image(systemName: selectedSection == .history ? "clipboard" : "star")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text(emptyStateText)
                        .multilineTextAlignment(.center).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 330)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardCard(
                            item: item,
                            shortcut: shortcutLabel(for: index),
                            isList: settings.displayMode == .list,
                            showsFavoriteIndicator: selectedSection == .history && favoritesStore.contains(item),
                            isFavorite: favoritesStore.contains(item),
                            toggleFavorite: { favoritesStore.toggle(item) },
                            favoriteActionTitle: Localizer.text(
                                favoritesStore.contains(item) ? .removeFromFavorites : .addToFavorites,
                                language: settings.language
                            )
                        ) {
                            select(item, settings.automaticPaste, true)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 56)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color.black.opacity(0.08))
    }

    private var emptyStateText: String {
        if !searchText.isEmpty {
            return Localizer.text(.noSearchResults, language: settings.language)
        }
        return Localizer.text(
            selectedSection == .history ? .emptyHistory : .emptyFavorites,
            language: settings.language
        )
    }

    private var sectionSwitcher: some View {
        HStack(spacing: 5) {
            sectionButton(.history)
            sectionButton(.favorites)
        }
        .padding(4)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.24), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
    }

    private func sectionButton(_ section: ClipboardSection) -> some View {
        let isSelected = selectedSection == section

        return Button {
            withAnimation(.easeOut(duration: 0.14)) {
                selectedSection = section
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section == .history ? "clock.arrow.circlepath" : "star.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(Localizer.text(section == .history ? .history : .favorites, language: settings.language))
                    .font(.system(size: 12, weight: .semibold))

                if isSelected && !searchText.isEmpty {
                    Text("\(filteredItems.count)")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.18), in: Capsule())
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.secondary)
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(
                isSelected ? Color.accentColor.opacity(0.7) : Color.clear,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var footerActions: some View {
        VStack(spacing: 0) {
            Button(action: store.clear) {
                footerLabel(Localizer.text(.clearHistory, language: settings.language))
            }
            .buttonStyle(MenuItemButtonStyle())

            Button(action: openSettings) {
                footerLabel(
                    Localizer.text(.settings, language: settings.language),
                    shortcut: shortcutSettings.shortcut(for: .openSettings).displayString
                )
            }
            .buttonStyle(MenuItemButtonStyle())

            Divider()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            Button(role: .destructive, action: quit) {
                footerLabel(
                    Localizer.text(.quit, language: settings.language),
                    shortcut: shortcutSettings.shortcut(for: .quit).displayString
                )
            }
            .buttonStyle(MenuItemButtonStyle())
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
    }

    private func shortcutLabel(for index: Int) -> String? {
        guard let action = ShortcutAction.selectItem(at: index) else { return nil }
        return shortcutSettings.shortcut(for: action).displayString
    }
    
    private func footerLabel(_ title: String, shortcut: String? = nil) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let shortcut {
                Text(shortcut)
                    .opacity(0.65)
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
    let shortcut: String?
    let isList: Bool
    let showsFavoriteIndicator: Bool
    let isFavorite: Bool
    let toggleFavorite: () -> Void
    let favoriteActionTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
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

                if showsFavoriteIndicator {
                    Image(systemName: "star.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }

                if let shortcut {
                    Text(shortcut)
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(.white)
                        .padding(5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
            .frame(height: 98)
            .contentShape(Rectangle())
        }
        .buttonStyle(CardButtonStyle())
        .contextMenu {
            Button(action: toggleFavorite) {
                Label(favoriteActionTitle, systemImage: isFavorite ? "star.slash" : "star")
            }
        }
    }
}

private enum ClipboardSection: String {
    case history
    case favorites
}

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        CardButton(configuration: configuration)
    }

    private struct CardButton: View {
        let configuration: Configuration
        @State private var isHovered = false

        private var isHighlighted: Bool {
            isHovered || configuration.isPressed
        }

        var body: some View {
            configuration.label
                .background(configuration.isPressed ? Color.accentColor.opacity(0.35) : Color.black.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isHighlighted ? Color.accentColor : Color.secondary.opacity(0.35))
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onHover { isHovered = $0 }
                .animation(.easeOut(duration: 0.08), value: isHighlighted)
        }
    }
}

private struct MenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MenuItemButton(configuration: configuration)
    }

    private struct MenuItemButton: View {
        let configuration: Configuration
        @State private var isHovered = false

        private var isHighlighted: Bool {
            isHovered || configuration.isPressed
        }

        var body: some View {
            configuration.label
                .foregroundStyle(isHighlighted ? Color.white : Color.primary)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isHighlighted ? Color.accentColor.opacity(0.7) : Color.clear)
                }
                .contentShape(Rectangle())
                .onHover { isHovered = $0 }
                .animation(.easeOut(duration: 0.08), value: isHighlighted)
        }
    }
}
