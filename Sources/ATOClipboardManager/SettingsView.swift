import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var launchAtLogin: LaunchAtLoginManager
    @ObservedObject var clipboardStore: ClipboardStore
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var shortcutSettings: ShortcutSettings
    @ObservedObject var accessibilityPermission: AccessibilityPermissionManager
    @State private var selectedTab: SettingsTab = .general
    @State private var showDeleteHistoryAfterDisabling = false
    @State private var releasePageIndex = 0

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            detail
        }
        .frame(width: 820, height: 620)
        .background(MacPalette.canvas)
        .tint(MacPalette.accent)
        .onAppear {
            launchAtLogin.refresh()
            accessibilityPermission.refresh()
            Task { await updateManager.checkIfNeeded() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            launchAtLogin.refresh()
            accessibilityPermission.refresh()
        }
        .onChange(of: updateManager.releases.count) { _ in
            releasePageIndex = releasePagination.pageIndex
        }
        .alert(
            Localizer.text(.launchAtLoginError, language: settings.language),
            isPresented: Binding(
                get: { launchAtLogin.errorMessage != nil },
                set: { if !$0 { launchAtLogin.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(launchAtLogin.errorMessage ?? "")
        }
        .alert(
            Localizer.text(.historyPersistenceError, language: settings.language),
            isPresented: Binding(
                get: { clipboardStore.persistenceError != nil },
                set: { if !$0 { clipboardStore.persistenceError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(clipboardStore.persistenceError ?? "")
        }
        .alert(
            Localizer.text(.updateError, language: settings.language),
            isPresented: Binding(
                get: { updateManager.errorMessage != nil },
                set: { if !$0 { updateManager.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(updateManager.errorMessage ?? "")
        }
        .alert(
            Localizer.text(.shortcutError, language: settings.language),
            isPresented: Binding(
                get: { shortcutSettings.issue != nil },
                set: { if !$0 { shortcutSettings.issue = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(shortcutIssueMessage)
        }
        .confirmationDialog(
            Localizer.text(.disablePersistenceTitle, language: settings.language),
            isPresented: $showDeleteHistoryAfterDisabling,
            titleVisibility: .visible
        ) {
            Button(Localizer.text(.deletePersistedHistory, language: settings.language), role: .destructive) {
                clipboardStore.deletePersistedHistory()
            }
            Button(Localizer.text(.keepPersistedHistory, language: settings.language), role: .cancel) {}
        } message: {
            Text(Localizer.text(.disablePersistenceMessage, language: settings.language))
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if let settingsIcon {
                    Image(nsImage: settingsIcon)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                        .frame(width: 46, height: 46)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [MacPalette.accent, MacPalette.accentDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: "clipboard.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 42, height: 42)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("ATO")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MacPalette.ink)
                    Text("Clipboard Manager")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MacPalette.mute)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 24)

            VStack(spacing: 4) {
                ForEach(SettingsTab.allCases) { tab in
                    sidebarButton(tab)
                }
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 20)

            HStack(spacing: 7) {
                Circle()
                    .fill(MacPalette.positive)
                    .frame(width: 6, height: 6)
                Text(Localizer.text(.version, language: settings.language))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MacPalette.mute)
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: 52)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(MacPalette.hairline)
                    .frame(height: 1)
            }
        }
        .frame(width: 210)
        .background(MacPalette.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(MacPalette.hairline)
                .frame(width: 1)
        }
    }

    private func sidebarButton(_ tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab
        let showsUpdateIndicator = tab == .updates && updateManager.availableUpdate != nil

        return Button {
            withAnimation(.easeOut(duration: 0.16)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? MacPalette.accent : MacPalette.mute)

                Text(tab.title(language: settings.language))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? MacPalette.ink : MacPalette.body)

                Spacer(minLength: 0)

                if showsUpdateIndicator {
                    Circle()
                        .fill(MacPalette.notification)
                        .frame(width: 5, height: 5)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 38)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? MacPalette.selected : Color.clear)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "Selected" : "")
    }

    private var settingsIcon: NSImage? {
        if let bundledIcon = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: bundledIcon) {
            return image
        }

        let sourceIcon = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("macos/atoClipboardManager-macOS/Assets.xcassets/AppIcon.appiconset/ATO_1024.png")
        return NSImage(contentsOf: sourceIcon)
    }

    private var detail: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Image(systemName: selectedTab.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MacPalette.accent)
                    .frame(width: 34, height: 34)
                    .background(MacPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(MacPalette.hairline)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedTab.title(language: settings.language))
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(MacPalette.ink)
                    Text(selectedTab.description(language: settings.language))
                        .font(.system(size: 12))
                        .foregroundStyle(MacPalette.mute)
                }
                Spacer()
            }
            .padding(.horizontal, 26)
            .frame(height: 78)
            .background(MacPalette.surface)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(MacPalette.hairline)
                    .frame(height: 1)
            }

            ScrollView {
                selectedTabContent
                    .padding(.horizontal, 26)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(MacPalette.canvas)

            footer
                .padding(.horizontal, 22)
                .frame(height: 52)
                .background(MacPalette.surface)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(MacPalette.hairline)
                        .frame(height: 1)
                }
        }
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .general:
            generalSettings
        case .behavior:
            behaviorSettings
        case .shortcuts:
            shortcutsSettings
        case .updates:
            updatesSettings
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsSection(Localizer.text(.general, language: settings.language)) {
                settingsPanel {
                    settingRow(Localizer.text(.language, language: settings.language)) {
                        Picker("", selection: $settings.language) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 170)
                    }

                    panelDivider

                    settingRow(Localizer.text(.theme, language: settings.language)) {
                        Picker("", selection: $settings.theme) {
                            Text(Localizer.text(.systemTheme, language: settings.language)).tag(AppTheme.system)
                            Text(Localizer.text(.lightTheme, language: settings.language)).tag(AppTheme.light)
                            Text(Localizer.text(.darkTheme, language: settings.language)).tag(AppTheme.dark)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 210)
                    }

                    panelDivider

                    settingRow(Localizer.text(.displayMode, language: settings.language)) {
                        Picker("", selection: $settings.displayMode) {
                            Text(Localizer.text(.grid, language: settings.language)).tag(DisplayMode.grid)
                            Text(Localizer.text(.list, language: settings.language)).tag(DisplayMode.list)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 170)
                    }

                    panelDivider

                    settingRow(Localizer.text(.maxHistory, language: settings.language)) {
                        numericInput(value: $settings.maxHistoryItems, range: 1...100)
                    }
                }
            }

            settingsSection(Localizer.text(.startup, language: settings.language)) {
                startupSettings
            }

            settingsSection(Localizer.text(.storage, language: settings.language)) {
                storageSettings
            }
        }
    }

    private var behaviorSettings: some View {
        settingsPanel {
            toggleRow(
                Localizer.text(.automaticPaste, language: settings.language),
                isOn: accessibilityAwareBinding($settings.automaticPaste)
            )

            panelDivider

            toggleRow(
                Localizer.text(.automaticPasteShortcut, language: settings.language),
                isOn: accessibilityAwareBinding($settings.automaticPasteShortcut)
            )

            panelDivider

            toggleRow(
                Localizer.text(.automaticPasteOnReturn, language: settings.language),
                isOn: accessibilityAwareBinding($settings.automaticPasteOnReturn)
            )

            if needsAccessibilityPermission {
                panelDivider
                accessibilityPermissionCallout
            }
        }
    }

    private var needsAccessibilityPermission: Bool {
        (settings.automaticPaste || settings.automaticPasteShortcut || settings.automaticPasteOnReturn)
            && !accessibilityPermission.isGranted
    }

    private var accessibilityPermissionCallout: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Localizer.text(.accessibilityPermissionRequired, language: settings.language))
                        .font(.system(size: 13, weight: .semibold))
                    Text(Localizer.text(.accessibilityPermissionExplanation, language: settings.language))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button(Localizer.text(.openAccessibilitySettings, language: settings.language)) {
                    accessibilityPermission.openSystemSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            HStack(spacing: 12) {
                DraggableApplicationIcon(
                    accessibilityLabel: Localizer.text(.draggableATOIcon, language: settings.language)
                )
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text(Localizer.text(.dragATOToAccessibility, language: settings.language))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MacPalette.body)
                    Text(Localizer.text(.dragATOToAccessibilityHint, language: settings.language))
                        .font(.system(size: 11))
                        .foregroundStyle(MacPalette.mute)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
            .background(MacPalette.selected, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(MacPalette.hairline)
            }
        }
    }

    private func accessibilityAwareBinding(_ binding: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { binding.wrappedValue },
            set: { enabled in
                binding.wrappedValue = enabled
                if enabled {
                    accessibilityPermission.refresh()
                }
            }
        )
    }

    private var shortcutsSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsSection(Localizer.text(.applicationShortcuts, language: settings.language)) {
                settingsPanel {
                    shortcutRow(.togglePopover)
                    panelDivider
                    shortcutRow(.showHistory)
                    panelDivider
                    shortcutRow(.showFavorites)
                    panelDivider
                    shortcutRow(.openSettings)
                    panelDivider
                    shortcutRow(.quit)
                }
            }

            settingsSection(Localizer.text(.historyShortcuts, language: settings.language)) {
                settingsPanel {
                    shortcutRow(.toggleSelectedItemPin)
                    panelDivider
                    ForEach(Array(1...9), id: \.self) { number in
                        if let action = ShortcutAction.selectItem(at: number - 1) {
                            shortcutRow(action)
                            if number < 9 { panelDivider }
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button(Localizer.text(.resetShortcuts, language: settings.language)) {
                    shortcutSettings.reset()
                }
            }
        }
    }

    private var startupSettings: some View {
        settingsPanel {
            toggleRow(
                Localizer.text(.launchAtLogin, language: settings.language),
                isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: launchAtLogin.setEnabled
                )
            )

            if launchAtLogin.requiresApproval {
                panelDivider

                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(Localizer.text(.launchAtLoginApproval, language: settings.language))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(Localizer.text(.openLoginItems, language: settings.language)) {
                        launchAtLogin.openSystemSettings()
                    }
                }
            }
        }
    }

    private var storageSettings: some View {
        settingsPanel {
            toggleRow(
                Localizer.text(.persistHistory, language: settings.language),
                isOn: Binding(
                    get: { settings.persistHistory },
                    set: { enabled in
                        let shouldAskToDelete = settings.persistHistory && !enabled && clipboardStore.hasPersistedHistory
                        settings.persistHistory = enabled
                        if shouldAskToDelete {
                            showDeleteHistoryAfterDisabling = true
                        }
                    }
                )
            )

            if settings.persistHistory {
                panelDivider

                settingRow(Localizer.text(.persistedHistoryLimit, language: settings.language)) {
                    numericInput(
                        value: $settings.maxPersistedHistoryItems,
                        range: settings.maxHistoryItems...AppSettings.maximumPersistedHistoryItems
                    )
                }
            }
        }
    }

    private var updatesSettings: some View {
        VStack(spacing: 14) {
            settingsPanel {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: updateManager.availableUpdate == nil ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(updateManager.availableUpdate == nil ? Color.green : Color.accentColor)

                    VStack(alignment: .leading, spacing: 3) {
                        if let release = updateManager.availableUpdate {
                            Text(String(
                                format: Localizer.text(.updateAvailable, language: settings.language),
                                release.version
                            ))
                            .font(.body.weight(.medium))
                            Text(Localizer.text(.downloadAndRestartHint, language: settings.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(Localizer.text(.upToDate, language: settings.language))
                                .font(.body.weight(.medium))
                            if let lastChecked = updateManager.lastChecked {
                                Text(String(
                                    format: Localizer.text(.lastChecked, language: settings.language),
                                    lastChecked.formatted(date: .abbreviated, time: .shortened)
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    if updateManager.isChecking || updateManager.isInstalling {
                        ProgressView()
                            .controlSize(.small)
                    }

                    if let release = updateManager.availableUpdate {
                        Button(Localizer.text(.downloadAndInstall, language: settings.language)) {
                            Task { await updateManager.install(release) }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(updateManager.isChecking || updateManager.isInstalling)

                        Button {
                            Task { await updateManager.checkIfNeeded(force: true) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help(Localizer.text(.checkForUpdates, language: settings.language))
                        .disabled(updateManager.isChecking || updateManager.isInstalling)
                    } else {
                        Button(Localizer.text(.checkForUpdates, language: settings.language)) {
                            Task { await updateManager.checkIfNeeded(force: true) }
                        }
                        .disabled(updateManager.isChecking || updateManager.isInstalling)
                    }
                }
            }

            settingsPanel {
                VStack(alignment: .leading, spacing: 10) {
                    Text(Localizer.text(.previousVersions, language: settings.language))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MacPalette.ink)

                    if updateManager.releases.isEmpty {
                        Text(Localizer.text(.noVersionsLoaded, language: settings.language))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(visibleReleases) { release in
                                HStack(spacing: 10) {
                                    Text("v\(release.version)")
                                        .font(.callout.weight(.medium))
                                        .frame(minWidth: 72, alignment: .leading)
                                        .help("v\(release.version)")
                                    Text(release.publishedAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize()
                                    Spacer()
                                    if VersionNumber(release.version) == VersionNumber(updateManager.currentVersion) {
                                        Text(Localizer.text(.installed, language: settings.language))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Link(destination: release.pageURL) {
                                        Image(systemName: "arrow.up.right.square")
                                    }
                                    .accessibilityLabel(Localizer.text(.releaseNotes, language: settings.language))
                                    .help(Localizer.text(.releaseNotes, language: settings.language))
                                }
                                .lineLimit(1)
                                .frame(minHeight: 26)
                                if release.id != visibleReleases.last?.id { Divider() }
                            }
                        }
                        if releasePagination.pageCount > 1 {
                            releasePaginationControls
                        }
                    }
                }
            }
        }
    }

    private var releasePagination: ReleasePagination {
        ReleasePagination(itemCount: updateManager.releases.count, pageIndex: releasePageIndex)
    }

    private var visibleReleases: [AppRelease] {
        Array(updateManager.releases[releasePagination.itemRange])
    }

    private var releasePaginationControls: some View {
        HStack(spacing: 12) {
            Text(String(
                format: Localizer.text(.releasePage, language: settings.language),
                releasePagination.pageIndex + 1,
                releasePagination.pageCount
            ))
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(.secondary)

            Spacer()

            Button {
                releasePageIndex = releasePagination.pageIndex - 1
            } label: {
                Label(Localizer.text(.previousReleasePage, language: settings.language), systemImage: "chevron.left")
            }
            .disabled(releasePagination.pageIndex == 0)

            Button {
                releasePageIndex = releasePagination.pageIndex + 1
            } label: {
                Label(Localizer.text(.nextReleasePage, language: settings.language), systemImage: "chevron.right")
            }
            .disabled(releasePagination.pageIndex == releasePagination.pageCount - 1)
        }
        .controlSize(.small)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Link(destination: URL(string: "https://github.com/simonepiteo/ato-clipboard-manager")!) {
                Label(Localizer.text(.sourceCode, language: settings.language), systemImage: "chevron.left.forwardslash.chevron.right")
            }
            .foregroundStyle(MacPalette.mute)

            Link(destination: URL(string: "https://github.com/simonepiteo/ato-clipboard-manager/blob/main/LICENSE")!) {
                Label(Localizer.text(.license, language: settings.language), systemImage: "doc.text")
            }
            .foregroundStyle(MacPalette.mute)

            Spacer()

            Button(Localizer.text(.resetSettings, language: settings.language), action: settings.reset)
                .foregroundStyle(MacPalette.notification)
        }
        .font(.system(size: 12, weight: .medium))
    }

    private var shortcutIssueMessage: String {
        switch shortcutSettings.issue {
        case .modifierRequired:
            Localizer.text(.shortcutModifierRequired, language: settings.language)
        case let .duplicate(action):
            String(
                format: Localizer.text(.shortcutDuplicate, language: settings.language),
                shortcutTitle(for: action)
            )
        case let .persistence(message):
            message
        case nil:
            ""
        }
    }

    private func shortcutRow(_ action: ShortcutAction) -> some View {
        settingRow(shortcutTitle(for: action)) {
            HStack(spacing: 7) {
                if shortcutSettings.isCustomized(action) {
                    Button {
                        shortcutSettings.reset(action)
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .help(Localizer.text(.resetShortcut, language: settings.language))
                }

                ShortcutRecorderView(
                    shortcut: shortcutSettings.shortcut(for: action),
                    prompt: Localizer.text(.recordShortcut, language: settings.language)
                ) { shortcut in
                    shortcutSettings.set(shortcut, for: action)
                }
                .frame(width: 140, height: 26)
            }
        }
    }

    private func shortcutTitle(for action: ShortcutAction) -> String {
        switch action {
        case .togglePopover:
            Localizer.text(.openPopoverShortcut, language: settings.language)
        case .openSettings:
            Localizer.text(.openSettingsShortcut, language: settings.language)
        case .quit:
            Localizer.text(.quitShortcut, language: settings.language)
        case .showHistory:
            Localizer.text(.showHistoryShortcut, language: settings.language)
        case .showFavorites:
            Localizer.text(.showFavoritesShortcut, language: settings.language)
        case .toggleSelectedItemPin:
            Localizer.text(.toggleSelectedItemPinShortcut, language: settings.language)
        default:
            String(
                format: Localizer.text(.selectItemShortcut, language: settings.language),
                (action.itemIndex ?? 0) + 1
            )
        }
    }

    private var panelDivider: some View {
        Rectangle()
            .fill(MacPalette.hairline)
            .frame(height: 1)
            .padding(.vertical, 4)
    }

    private func settingsPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            content()
        }
        .padding(16)
        .background(MacPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(MacPalette.hairline)
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MacPalette.mute)
                .padding(.leading, 4)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingRow<Control: View>(
        _ title: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(MacPalette.body)
            Spacer(minLength: 16)
            control()
        }
        .frame(minHeight: 30)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(MacPalette.body)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 16)
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .frame(minHeight: 30)
    }

    private func numericInput(value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 6) {
            Button {
                value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1)
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(NumericStepButtonStyle())
            .disabled(value.wrappedValue <= range.lowerBound)

            TextField("", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 64, height: 26)

            Button {
                value.wrappedValue = min(range.upperBound, value.wrappedValue + 1)
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(NumericStepButtonStyle())
            .disabled(value.wrappedValue >= range.upperBound)
        }
        .controlSize(.regular)
    }
}

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general, behavior, shortcuts, updates

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .behavior: "command"
        case .shortcuts: "keyboard"
        case .updates: "arrow.triangle.2.circlepath"
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .general: Localizer.text(.general, language: language)
        case .behavior: Localizer.text(.behavior, language: language)
        case .shortcuts: Localizer.text(.shortcuts, language: language)
        case .updates: Localizer.text(.updates, language: language)
        }
    }

    func description(language: AppLanguage) -> String {
        switch self {
        case .general: Localizer.text(.generalSettingsDescription, language: language)
        case .behavior: Localizer.text(.behaviorSettingsDescription, language: language)
        case .shortcuts: Localizer.text(.shortcutsSettingsDescription, language: language)
        case .updates: Localizer.text(.updatesSettingsDescription, language: language)
        }
    }
}

private struct NumericStepButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        NumericStepButton(configuration: configuration)
    }

    private struct NumericStepButton: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.system(size: 13, weight: .medium))
                .frame(width: 34, height: 26)
                .foregroundStyle(isEnabled ? MacPalette.ink : MacPalette.ash)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(configuration.isPressed ? MacPalette.selectedStrong : MacPalette.selected)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(MacPalette.hairline)
                }
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}

private enum MacPalette {
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let sidebar = Color(nsColor: .underPageBackgroundColor)
    static let surface = Color(nsColor: .windowBackgroundColor)
    static let surfaceElevated = Color(nsColor: .controlBackgroundColor)
    static let selected = Color(nsColor: .selectedContentBackgroundColor).opacity(0.16)
    static let selectedStrong = Color(nsColor: .selectedContentBackgroundColor).opacity(0.26)
    static let hairline = Color(nsColor: .separatorColor)
    static let ink = Color(nsColor: .labelColor)
    static let body = Color(nsColor: .labelColor)
    static let mute = Color(nsColor: .secondaryLabelColor)
    static let ash = Color(nsColor: .tertiaryLabelColor)
    static let accent = Color(nsColor: .controlAccentColor)
    static let accentDeep = Color(nsColor: .systemBlue)
    static let positive = Color(nsColor: .systemGreen)
    static let notification = Color(nsColor: .systemRed)
}
