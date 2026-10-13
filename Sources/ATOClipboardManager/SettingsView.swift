import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var launchAtLogin: LaunchAtLoginManager
    @ObservedObject var clipboardStore: ClipboardStore
    @ObservedObject var updateManager: UpdateManager
    @State private var selectedTab: SettingsTab = .general
    @State private var showDeleteHistoryAfterDisabling = false

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
        }
        .frame(width: 760, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
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
            HStack(spacing: 11) {
                Image(systemName: "clipboard.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text("ATO")
                        .font(.headline)
                    Text("Clipboard Manager")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 12)

            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.title(language: settings.language), systemImage: tab.systemImage)
                    .tag(tab)
                    .padding(.vertical, 3)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Text(Localizer.text(.version, language: settings.language))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 17)
                .padding(.bottom, 14)
        }
        .frame(width: 190)
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private var detail: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: selectedTab.systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 38, height: 38)
                    .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedTab.title(language: settings.language))
                        .font(.title2.weight(.semibold))
                    Text(selectedTab.description(language: settings.language))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            Divider()

            ScrollView {
                selectedTabContent
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            Divider()
            footer
                .padding(.horizontal, 20)
                .frame(height: 48)
        }
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .general:
            generalSettings
        case .behavior:
            behaviorSettings
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
        VStack(spacing: 16) {
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
                        .font(.headline)

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

            Link(destination: URL(string: "https://github.com/simonepiteo/ato-clipboard-manager/blob/main/LICENSE")!) {
                Label(Localizer.text(.license, language: settings.language), systemImage: "doc.text")
            }

            Spacer()

            Button(Localizer.text(.resetSettings, language: settings.language), action: settings.reset)
        }
        .font(.callout)
    }

    private var panelDivider: some View {
        Divider().padding(.vertical, 4)
    }

    private func settingsPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            content()
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.07))
        }
    }

    private func settingRow<Control: View>(
        _ title: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 16) {
            Text(title)
            Spacer(minLength: 16)
            control()
        }
        .frame(minHeight: 28)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 16)
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .frame(minHeight: 28)
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
                .frame(width: 64, height: 24)

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
    case general, behavior, startup, storage, updates

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .behavior: "command"
        case .startup: "power"
        case .storage: "externaldrive"
        case .updates: "arrow.triangle.2.circlepath"
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .general: Localizer.text(.general, language: language)
        case .behavior: Localizer.text(.behavior, language: language)
        case .startup: Localizer.text(.startup, language: language)
        case .storage: Localizer.text(.storage, language: language)
        case .updates: Localizer.text(.updates, language: language)
        }
    }

    func description(language: AppLanguage) -> String {
        switch self {
        case .general: Localizer.text(.generalSettingsDescription, language: language)
        case .behavior: Localizer.text(.behaviorSettingsDescription, language: language)
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
                .frame(width: 34, height: 24)
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.55))
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(configuration.isPressed ? 0.16 : 0.10))
                }
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}
