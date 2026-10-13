import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var launchAtLogin: LaunchAtLoginManager
    @ObservedObject var clipboardStore: ClipboardStore
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var shortcutSettings: ShortcutSettings
    @State private var selectedTab: SettingsTab = .general
    @State private var showDeleteHistoryAfterDisabling = false

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            detail
        }
        .frame(width: 820, height: 620)
        .background(RaycastPalette.canvas)
        .tint(RaycastPalette.accentRed)
        .preferredColorScheme(.dark)
        .onAppear {
            launchAtLogin.refresh()
            Task { await updateManager.checkIfNeeded() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            launchAtLogin.refresh()
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
                                    colors: [RaycastPalette.accentRed, RaycastPalette.accentRedDeep],
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
                        .foregroundStyle(RaycastPalette.ink)
                    Text("Clipboard Manager")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(RaycastPalette.mute)
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
                    .fill(RaycastPalette.accentGreen)
                    .frame(width: 6, height: 6)
                Text(Localizer.text(.version, language: settings.language))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RaycastPalette.mute)
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: 52)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(RaycastPalette.hairline)
                    .frame(height: 1)
            }
        }
        .frame(width: 210)
        .background(RaycastPalette.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(RaycastPalette.hairline)
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
                    .foregroundStyle(isSelected ? RaycastPalette.ink : RaycastPalette.mute)

                Text(tab.title(language: settings.language))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? RaycastPalette.ink : RaycastPalette.body)

                Spacer(minLength: 0)

                if showsUpdateIndicator {
                    Circle()
                        .fill(RaycastPalette.accentRed)
                        .frame(width: 5, height: 5)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 38)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? RaycastPalette.selected : Color.clear)
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
                    .foregroundStyle(RaycastPalette.ink)
                    .frame(width: 34, height: 34)
                    .background(RaycastPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(RaycastPalette.hairline)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedTab.title(language: settings.language))
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(RaycastPalette.ink)
                    Text(selectedTab.description(language: settings.language))
                        .font(.system(size: 12))
                        .foregroundStyle(RaycastPalette.mute)
                }
                Spacer()
            }
            .padding(.horizontal, 26)
            .frame(height: 78)
            .background(RaycastPalette.surface)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(RaycastPalette.hairline)
                    .frame(height: 1)
            }

            ScrollView {
                selectedTabContent
                    .padding(.horizontal, 26)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(RaycastPalette.canvas)

            footer
                .padding(.horizontal, 22)
                .frame(height: 52)
                .background(RaycastPalette.surface)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(RaycastPalette.hairline)
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
        case .startup:
            startupSettings
        case .storage:
            storageSettings
        case .updates:
            updatesSettings
        }
    }

    private var generalSettings: some View {
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

    private var behaviorSettings: some View {
        settingsPanel {
            toggleRow(
                Localizer.text(.automaticPaste, language: settings.language),
                isOn: $settings.automaticPaste
            )

            panelDivider

            toggleRow(
                Localizer.text(.automaticPasteShortcut, language: settings.language),
                isOn: $settings.automaticPasteShortcut
            )
        }
    }

    private var shortcutsSettings: some View {
        VStack(spacing: 14) {
            settingsPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Localizer.text(.applicationShortcuts, language: settings.language))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RaycastPalette.ink)

                    shortcutRow(.togglePopover)
                    panelDivider
                    shortcutRow(.openSettings)
                    panelDivider
                    shortcutRow(.quit)
                }
            }

            settingsPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Localizer.text(.historyShortcuts, language: settings.language))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RaycastPalette.ink)

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
                        .foregroundStyle(RaycastPalette.ink)

                    if updateManager.releases.isEmpty {
                        Text(Localizer.text(.noVersionsLoaded, language: settings.language))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(updateManager.releases) { release in
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("v\(release.version)")
                                            .font(.callout.weight(.medium))
                                        Text(release.publishedAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if VersionNumber(release.version) == VersionNumber(updateManager.currentVersion) {
                                        Text(Localizer.text(.installed, language: settings.language))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Link(destination: release.pageURL) {
                                        Image(systemName: "arrow.up.right.square")
                                    }
                                    .help(Localizer.text(.releaseNotes, language: settings.language))
                                }
                                .padding(.vertical, 8)
                                if release.id != updateManager.releases.last?.id { Divider() }
                            }
                        }
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Link(destination: URL(string: "https://github.com/simonepiteo/ato-clipboard-manager")!) {
                Label(Localizer.text(.sourceCode, language: settings.language), systemImage: "chevron.left.forwardslash.chevron.right")
            }
            .foregroundStyle(RaycastPalette.mute)

            Link(destination: URL(string: "https://github.com/simonepiteo/ato-clipboard-manager/blob/main/LICENSE")!) {
                Label(Localizer.text(.license, language: settings.language), systemImage: "doc.text")
            }
            .foregroundStyle(RaycastPalette.mute)

            Spacer()

            Button(Localizer.text(.resetSettings, language: settings.language), action: settings.reset)
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
        default:
            String(
                format: Localizer.text(.selectItemShortcut, language: settings.language),
                (action.itemIndex ?? 0) + 1
            )
        }
    }

    private var panelDivider: some View {
        Rectangle()
            .fill(RaycastPalette.hairline)
            .frame(height: 1)
            .padding(.vertical, 4)
    }

    private func settingsPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            content()
        }
        .padding(16)
        .background(RaycastPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(RaycastPalette.hairline)
        }
    }

    private func settingRow<Control: View>(
        _ title: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(RaycastPalette.body)
            Spacer(minLength: 16)
            control()
        }
        .frame(minHeight: 30)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(RaycastPalette.body)
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
    case general, behavior, shortcuts, startup, storage, updates

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .behavior: "command"
        case .shortcuts: "keyboard"
        case .startup: "power"
        case .storage: "externaldrive"
        case .updates: "arrow.triangle.2.circlepath"
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .general: Localizer.text(.general, language: language)
        case .behavior: Localizer.text(.behavior, language: language)
        case .shortcuts: Localizer.text(.shortcuts, language: language)
        case .startup: Localizer.text(.startup, language: language)
        case .storage: Localizer.text(.storage, language: language)
        case .updates: Localizer.text(.updates, language: language)
        }
    }

    func description(language: AppLanguage) -> String {
        switch self {
        case .general: Localizer.text(.generalSettingsDescription, language: language)
        case .behavior: Localizer.text(.behaviorSettingsDescription, language: language)
        case .shortcuts: Localizer.text(.shortcutsSettingsDescription, language: language)
        case .startup: Localizer.text(.startupSettingsDescription, language: language)
        case .storage: Localizer.text(.storageSettingsDescription, language: language)
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
                .foregroundStyle(isEnabled ? RaycastPalette.ink : RaycastPalette.ash)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(configuration.isPressed ? RaycastPalette.selectedStrong : RaycastPalette.selected)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(RaycastPalette.hairline)
                }
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}

private enum RaycastPalette {
    static let canvas = Color(red: 0.027, green: 0.031, blue: 0.039)
    static let sidebar = Color(red: 0.039, green: 0.043, blue: 0.051)
    static let surface = Color(red: 0.051, green: 0.051, blue: 0.051)
    static let surfaceElevated = Color(red: 0.071, green: 0.071, blue: 0.071)
    static let selected = Color.white.opacity(0.075)
    static let selectedStrong = Color.white.opacity(0.13)
    static let hairline = Color.white.opacity(0.085)
    static let ink = Color(red: 0.957, green: 0.957, blue: 0.965)
    static let body = Color(red: 0.804, green: 0.804, blue: 0.804)
    static let mute = Color(red: 0.612, green: 0.612, blue: 0.616)
    static let ash = Color(red: 0.416, green: 0.420, blue: 0.424)
    static let accentRed = Color(red: 1.0, green: 0.38, blue: 0.38)
    static let accentRedDeep = Color(red: 0.63, green: 0.075, blue: 0.102)
    static let accentGreen = Color(red: 0.349, green: 0.831, blue: 0.600)
}
