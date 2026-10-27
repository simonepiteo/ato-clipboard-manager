import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PopoverView: View {
    static let baseSize = NSSize(width: 350, height: 450)
    static let selectionToolbarHeight: CGFloat = 36
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ObservedObject var store: ClipboardStore
    @ObservedObject var settings: AppSettings
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var shortcutSettings: ShortcutSettings
    @ObservedObject var favoritesStore: FavoritesStore
    @State private var searchText = ""
    @State private var dismissedUpdateVersion: String?
    @State private var selectedSection: ClipboardSection = .history
    @State private var keyboardSelectedItemID: UUID?
    @State private var selection = ClipboardSelection()
    @Namespace private var sectionSelectionNamespace

    let select: (ClipboardItem, Bool, Bool) -> Void
    let openSettings: () -> Void
    let quit: () -> Void
    let resizePopover: (NSSize) -> Void

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
            VStack(spacing: 0) {
                selectionToolbar
                Divider()
                    .frame(height: 1)
            }
            .frame(height: selection.isActive ? Self.selectionToolbarHeight + 1 : 0, alignment: .top)
            .opacity(selection.isActive ? 1 : 0)
            .clipped()
            .allowsHitTesting(selection.isActive)
            .accessibilityHidden(!selection.isActive)
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
        .modifier(SelectionPopoverLayout(expansion: selection.isActive ? 1 : 0, resizePopover: resizePopover))
        .background(.ultraThinMaterial)
        .animation(
            reduceMotion ? .easeOut(duration: 0.12)
                : .timingCurve(0.16, 1, 0.3, 1, duration: selection.isActive ? 0.28 : 0.22),
            value: selection.isActive
        )
        .onReceive(NotificationCenter.default.publisher(for: .selectClipboardHistoryItem)) { notification in
            guard let index = notification.userInfo?["index"] as? Int,
                  filteredItems.indices.contains(index)
            else { return }
            activateItem(filteredItems[index], paste: settings.automaticPasteShortcut, waitForClick: false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchClipboardSection)) { notification in
            guard let rawValue = notification.userInfo?["section"] as? String,
                  let section = ClipboardSection(rawValue: rawValue)
            else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                selectedSection = section
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateClipboardHistory)) { notification in
            guard let rawValue = notification.userInfo?["command"] as? String,
                  let command = ClipboardKeyboardCommand(rawValue: rawValue)
            else { return }
            handleKeyboardCommand(command)
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetClipboardKeyboardSelection)) { _ in
            exitSelectionMode()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exitClipboardSelection)) { notification in
            guard selection.isActive,
                  let request = notification.object as? ClipboardSelectionExitRequest else { return }
            request.wasHandled = true
            exitSelectionMode()
        }
        .onDisappear { exitSelectionMode() }
        .onChange(of: searchText) { _ in
            keyboardSelectedItemID = nil
            CardHoverZoomController.shared.cancel(animated: false)
        }
        .onChange(of: selectedSection) { _ in
            keyboardSelectedItemID = nil
            CardHoverZoomController.shared.cancel(animated: false)
        }
        .onChange(of: filteredItems.map(\.id)) { itemIDs in
            selection.retain(Set(itemIDs))
            guard let keyboardSelectedItemID, itemIDs.contains(keyboardSelectedItemID) else {
                self.keyboardSelectedItemID = nil
                return
            }
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
        .alert(
            Localizer.text(.historyPersistenceError, language: settings.language),
            isPresented: Binding(
                get: { store.persistenceError != nil },
                set: { if !$0 { store.persistenceError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.persistenceError ?? "")
        }
    }

    private func items(for section: ClipboardSection) -> [ClipboardItem] {
        section == .history ? store.items : favoritesStore.items
    }

    private func searchResultCount(for section: ClipboardSection) -> Int {
        items(for: section).filter {
            $0.searchableText.localizedCaseInsensitiveContains(searchText)
        }.count
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
        ScrollViewReader { proxy in
            ScrollView {
                if filteredItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: selectedSection == .history ? "clipboard" : "pin")
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
                                language: settings.language,
                                isKeyboardSelected: keyboardSelectedItemID == item.id,
                                isSelectionMode: selection.isActive,
                                isBatchSelected: selection.itemIDs.contains(item.id),
                                selectForBatch: {
                                    keyboardSelectedItemID = item.id
                                    if selection.itemIDs.contains(item.id) {
                                        selection.toggle(item.id)
                                    } else {
                                        selection.begin(with: item.id)
                                    }
                                },
                                showsFavoriteIndicator: selectedSection == .history && favoritesStore.contains(item),
                                isFavorite: favoritesStore.contains(item),
                                toggleFavorite: { favoritesStore.toggle(item) },
                                favoriteActionTitle: Localizer.text(
                                    favoritesStore.contains(item) ? .removeFromFavorites : .addToFavorites,
                                    language: settings.language
                                ),
                                deleteFromHistory: {
                                    guard !favoritesStore.contains(item) else { return }
                                    store.delete(item)
                                },
                                deleteActionTitle: Localizer.text(
                                    favoritesStore.contains(item) ? .unpinBeforeDeleting : .deleteFromHistory,
                                    language: settings.language
                                ),
                                hoverZoomEnabled: settings.hoverZoomEnabled,
                                hoverZoomDelay: TimeInterval(settings.hoverZoomDelay)
                            ) {
                                activateItem(item, paste: settings.automaticPaste, waitForClick: true)
                            }
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 56)
                }
            }
            .onChange(of: keyboardSelectedItemID) { itemID in
                CardHoverZoomController.shared.followKeyboardSelection(itemID)
                guard let itemID else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(itemID, anchor: .center)
                }
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color.black.opacity(0.08))
    }

    private func handleKeyboardCommand(_ command: ClipboardKeyboardCommand) {
        if command == .zoom {
            guard settings.hoverZoomEnabled, let keyboardSelectedItemID else { return }
            CardHoverZoomController.shared.toggleKeyboardZoom(itemID: keyboardSelectedItemID)
            return
        }
        if command == .beginSelection {
            guard !selection.isActive else { return }
            selection.begin(with: keyboardSelectedItemID)
            return
        }
        guard !filteredItems.isEmpty else { return }

        if command == .togglePin, selection.isActive {
            favoritesStore.toggle(selectedItems)
            return
        }

        if command == .select || command == .togglePin {
            guard let keyboardSelectedItemID,
                  let item = filteredItems.first(where: { $0.id == keyboardSelectedItemID })
            else { return }
            if command == .togglePin {
                favoritesStore.toggle(item)
            } else {
                activateItem(item, paste: settings.automaticPasteOnReturn, waitForClick: false)
            }
            return
        }

        guard let selectedItemID = keyboardSelectedItemID else {
            self.keyboardSelectedItemID = filteredItems[0].id
            return
        }

        let currentIndex = filteredItems.firstIndex { $0.id == selectedItemID }
        guard let currentIndex else {
            self.keyboardSelectedItemID = filteredItems[0].id
            return
        }
        let columnCount = settings.displayMode == .grid ? 3 : 1
        let delta: Int
        switch command {
        case .moveLeft: delta = -1
        case .moveRight: delta = 1
        case .moveUp: delta = -columnCount
        case .moveDown: delta = columnCount
        case .select, .togglePin, .beginSelection, .zoom: return
        }

        let proposedIndex = currentIndex + delta
        let nextIndex = min(max(proposedIndex, 0), filteredItems.count - 1)
        keyboardSelectedItemID = filteredItems[nextIndex].id
    }

    private func activateItem(_ item: ClipboardItem, paste: Bool, waitForClick: Bool) {
        if selection.isActive {
            keyboardSelectedItemID = item.id
            selection.toggle(item.id)
        } else {
            select(item, paste, waitForClick)
        }
    }

    private var selectedItems: [ClipboardItem] {
        filteredItems.filter { selection.itemIDs.contains($0.id) }
    }

    private func exitSelectionMode() {
        keyboardSelectedItemID = nil
        selection.end()
    }

    private var selectionToolbar: some View {
        let selected = selectedItems
        let allSelected = !filteredItems.isEmpty && selected.count == filteredItems.count
        let containsPinned = selected.contains { favoritesStore.contains($0) }
        let allPinned = !selected.isEmpty && selected.allSatisfy { favoritesStore.contains($0) }

        return HStack(spacing: 6) {
            Button(Localizer.text(allSelected ? .deselectAll : .selectAll, language: settings.language)) {
                selection.toggleAll(Set(filteredItems.map(\.id)))
            }
            .disabled(filteredItems.isEmpty)

            Spacer(minLength: 0)

            selectionToolbarButton(
                allPinned ? .unpinSelected : .pinSelected,
                icon: allPinned ? "pin.slash.fill" : "pin.fill",
                disabled: selected.isEmpty
            ) {
                favoritesStore.toggle(selected)
            }
            selectionToolbarButton(
                containsPinned ? .unpinBeforeDeleting : .deleteSelected,
                icon: "trash.fill",
                disabled: selected.isEmpty || containsPinned
            ) {
                guard !selected.contains(where: { favoritesStore.contains($0) }) else { return }
                store.delete(selected)
            }
            selectionToolbarButton(.exitSelectionMode, icon: "xmark.circle.fill") {
                exitSelectionMode()
            }
        }
        .controlSize(.small)
        .padding(.horizontal, 10)
        .frame(height: Self.selectionToolbarHeight)
        .background(Color.accentColor.opacity(0.08))
    }

    private func selectionToolbarButton(
        _ title: LocalizedKey,
        icon: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 12, height: 12, alignment: .center)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Localizer.text(title, language: settings.language))
        .help(Localizer.text(title, language: settings.language))
        .disabled(disabled)
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
        let resultCount = searchResultCount(for: section)
        let showsSearchCount = !searchText.isEmpty && resultCount > 0

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                selectedSection = section
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section == .history ? "clock.arrow.circlepath" : "pin.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(Localizer.text(section == .history ? .history : .favorites, language: settings.language))
                    .font(.system(size: 12, weight: .semibold))

                if showsSearchCount {
                    Text("\(resultCount)")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ? Color.white.opacity(0.18) : Color.primary.opacity(0.10),
                            in: Capsule()
                        )
                        .transition(.scale(scale: 0.72).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: showsSearchCount)
            .foregroundStyle(isSelected ? Color.white : Color.secondary)
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor.opacity(0.7))
                        .matchedGeometryEffect(
                            id: "sectionSelection",
                            in: sectionSelectionNamespace
                        )
                }
            }
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

private struct SelectionPopoverLayout: AnimatableModifier {
    var expansion: CGFloat
    let resizePopover: (NSSize) -> Void

    var animatableData: CGFloat {
        get { expansion }
        set { expansion = newValue }
    }

    func body(content: Content) -> some View {
        let size = NSSize(
            width: PopoverView.baseSize.width,
            height: PopoverView.baseSize.height + (PopoverView.selectionToolbarHeight + 1) * expansion
        )
        return content
            .frame(width: size.width, height: size.height)
            .background {
                PopoverSizeReporter(size: size, resizePopover: resizePopover)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

private struct PopoverSizeReporter: NSViewRepresentable {
    let size: NSSize
    let resizePopover: (NSSize) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.resizePopover = resizePopover
        context.coordinator.request(size)
    }

    final class Coordinator {
        var resizePopover: ((NSSize) -> Void)?
        private var pendingSize: NSSize?
        private var lastSize: NSSize?
        private var isScheduled = false

        func request(_ size: NSSize) {
            guard size != lastSize else { return }
            lastSize = size
            pendingSize = size
            guard !isScheduled else { return }
            isScheduled = true
            // Resize outside SwiftUI's layout pass; coalesce to the latest animation frame.
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isScheduled = false
                guard let size = self.pendingSize else { return }
                self.pendingSize = nil
                self.resizePopover?(size)
            }
        }
    }
}

struct ClipboardCard: View {
    let item: ClipboardItem
    let shortcut: String?
    let isList: Bool
    let language: AppLanguage
    let isKeyboardSelected: Bool
    let isSelectionMode: Bool
    let isBatchSelected: Bool
    let selectForBatch: () -> Void
    let showsFavoriteIndicator: Bool
    let isFavorite: Bool
    let toggleFavorite: () -> Void
    let favoriteActionTitle: String
    let deleteFromHistory: () -> Void
    let deleteActionTitle: String
    var hoverZoomEnabled = true
    var hoverZoomDelay: TimeInterval = TimeInterval(AppSettings.defaultHoverZoomDelay)
    let action: () -> Void

    private func cardButton(expanded: Bool = false) -> some View {
        Button {
            CardHoverZoomController.shared.activateCard(itemID: item.id, action: action)
        } label: {
            ZStack {
                Group {
                    switch item.content {
                    case let .text(text):
                        Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                            .lineLimit(expanded ? nil : (isList ? 4 : 6))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    case let .image(data):
                        if let image = NSImage(data: data) {
                            Image(nsImage: image).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    case let .files(files):
                        FileClipboardPreview(
                            files: files,
                            isList: isList,
                            language: language,
                            expanded: expanded
                        )
                    }
                }
                .padding(6)

                if isSelectionMode {
                    Image(systemName: isBatchSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isBatchSelected ? Color.accentColor : Color.secondary)
                        .background(.regularMaterial, in: Circle())
                        .accessibilityHidden(true)
                        .padding(5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }

                if showsFavoriteIndicator {
                    Image(systemName: "pin.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 4))
                        .padding(5)
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
            .frame(height: expanded ? nil : 98)
            .contentShape(Rectangle())
        }
        .buttonStyle(CardButtonStyle(isKeyboardSelected: isKeyboardSelected, isBatchSelected: isBatchSelected))
    }

    var hoverPreview: CardHoverPreview {
        CardHoverPreview(content: AnyView(cardButton(expanded: true)))
    }

    var body: some View {
        cardButton()
        .modifier(CardHoverZoom(itemID: item.id, preview: hoverPreview, enabled: hoverZoomEnabled, delay: hoverZoomDelay))
        .accessibilityAddTraits((isSelectionMode ? isBatchSelected : isKeyboardSelected) ? .isSelected : [])
        .contextMenu {
            Button(action: selectForBatch) {
                Label(
                    Localizer.text(isBatchSelected ? .deselectCard : .selectCard, language: language),
                    systemImage: isBatchSelected ? "minus.circle.fill" : "checkmark.circle.fill"
                )
            }

            Button(action: toggleFavorite) {
                Label(favoriteActionTitle, systemImage: isFavorite ? "pin.slash.fill" : "pin.fill")
            }

            Button {
                CardHoverZoomController.shared.enlarge(itemID: item.id)
            } label: {
                Label(Localizer.text(.enlargeCard, language: language), systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .disabled(!hoverZoomEnabled)

            Divider()

            Button(role: .destructive, action: deleteFromHistory) {
                Label(deleteActionTitle, systemImage: "trash.fill")
            }
            .disabled(isFavorite)
        }
    }
}

private struct FileClipboardPreview: View {
    let files: [ClipboardFile]
    let isList: Bool
    let language: AppLanguage
    var expanded = false

    var body: some View {
        Group {
            if expanded, files.count == 1, let file = files.first {
                SingleFileClipboardPreview(file: file, language: language, icon: icon(for: file))
            } else if expanded {
                expandedContents
            } else {
                compactContents
            }
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 13)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(files.map(\.name).joined(separator: ", "))
    }

    private var expandedContents: some View {
        GeometryReader { geometry in
            let capacity = min(4, max(1, Int((geometry.size.height - 28) / 29)))
            let visibleFiles = Array(files.prefix(capacity))
            VStack(alignment: .leading, spacing: 3) {
                Text(fileCountLabel)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                ForEach(visibleFiles) { file in
                    HStack(spacing: 6) {
                        fileIcon(for: file, size: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(file.name)
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text(file.url.deletingLastPathComponent().path)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 26)
                }
                if files.count > visibleFiles.count {
                    Text(String(
                        format: Localizer.text(
                            files.count - visibleFiles.count == 1 ? .additionalFileSingular : .additionalFilePlural,
                            language: language
                        ),
                        files.count - visibleFiles.count
                    ))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var compactContents: some View {
        VStack(spacing: files.count == 1 ? 5 : 2) {
            if let file = files.first, files.count == 1 {
                fileIcon(for: file, size: 38)
                Text(file.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.center)
            } else {
                overlappingIcons
                Text(fileCountLabel)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(fileSummary)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var overlappingIcons: some View {
        HStack(spacing: -10) {
            ForEach(Array(files.prefix(3).enumerated()), id: \.element.id) { index, file in
                fileIcon(for: file, size: 31)
                    .zIndex(Double(3 - index))
            }
        }
        .frame(height: 32)
    }

    private var fileCountLabel: String {
        String(
            format: Localizer.text(
                files.count == 1 ? .fileCountSingular : .fileCountPlural,
                language: language
            ),
            files.count
        )
    }

    private var fileSummary: String {
        let names = files.prefix(isList ? 3 : 2).map(\.name).joined(separator: ", ")
        let remaining = files.count - min(files.count, isList ? 3 : 2)
        return remaining > 0 ? "\(names)  +\(remaining)" : names
    }

    private func fileIcon(for file: ClipboardFile, size: CGFloat) -> some View {
        Image(nsImage: icon(for: file))
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.16), radius: 1.5, y: 1)
    }

    private func icon(for file: ClipboardFile) -> NSImage {
        if FileManager.default.fileExists(atPath: file.path) {
            return NSWorkspace.shared.icon(forFile: file.path)
        }
        if !file.url.pathExtension.isEmpty,
           let type = UTType(filenameExtension: file.url.pathExtension) {
            return NSWorkspace.shared.icon(for: type)
        }
        return NSImage(systemSymbolName: "doc", accessibilityDescription: nil) ?? NSImage()
    }
}

private enum ClipboardSection: String {
    case history
    case favorites
}

private struct CardButtonStyle: ButtonStyle {
    let isKeyboardSelected: Bool
    let isBatchSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        CardButton(configuration: configuration, isKeyboardSelected: isKeyboardSelected, isBatchSelected: isBatchSelected)
    }

    private struct CardButton: View {
        let configuration: Configuration
        let isKeyboardSelected: Bool
        let isBatchSelected: Bool
        @State private var isHovered = false

        private var isHighlighted: Bool {
            isHovered || configuration.isPressed || isKeyboardSelected || isBatchSelected
        }

        var body: some View {
            configuration.label
                .background(
                    configuration.isPressed
                        ? Color.accentColor.opacity(0.35)
                        : (isKeyboardSelected || isBatchSelected) ? Color.accentColor.opacity(0.22) : Color.black.opacity(0.10)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isHighlighted ? Color.accentColor : Color.secondary.opacity(0.35),
                            lineWidth: isKeyboardSelected ? 2 : 1
                        )
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
