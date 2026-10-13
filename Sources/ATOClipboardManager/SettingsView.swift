import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var launchAtLogin: LaunchAtLoginManager
    @ObservedObject var clipboardStore: ClipboardStore
    @ObservedObject var updateManager: UpdateManager
    @State private var showDeletePersistedHistoryConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    settingsSection(
                        Localizer.text(.appearance, language: settings.language),
                        systemImage: "rectangle.grid.2x2"
                    ) {
                        settingRow(Localizer.text(.language, language: settings.language)) {
                            Picker("", selection: $settings.language) {
                                ForEach(AppLanguage.allCases) { language in
                                    Text(language.displayName).tag(language)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 160)
                        }

                        settingRow(Localizer.text(.displayMode, language: settings.language)) {
                            Picker("", selection: $settings.displayMode) {
                                Text(Localizer.text(.grid, language: settings.language)).tag(DisplayMode.grid)
                                Text(Localizer.text(.list, language: settings.language)).tag(DisplayMode.list)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .frame(width: 160)
                        }

                        settingRow(Localizer.text(.maxHistory, language: settings.language)) {
                            Stepper(value: $settings.maxHistoryItems, in: 1...100) {
                                Text("\(settings.maxHistoryItems)")
                                    .monospacedDigit()
                                    .frame(minWidth: 28, alignment: .trailing)
                            }
                            .frame(width: 110)
                        }
                    }

                    settingsSection(
                        Localizer.text(.behavior, language: settings.language),
                        systemImage: "command"
                    ) {
                        toggleRow(
                            Localizer.text(.automaticPaste, language: settings.language),
                            isOn: $settings.automaticPaste
                        )
                        toggleRow(
                            Localizer.text(.automaticPasteShortcut, language: settings.language),
                            isOn: $settings.automaticPasteShortcut
                        )
                    }

                    settingsSection(
                        Localizer.text(.startup, language: settings.language),
                        systemImage: "power"
                    ) {
                        toggleRow(
                            Localizer.text(.launchAtLogin, language: settings.language),
                            isOn: Binding(
                                get: { launchAtLogin.isEnabled },
                                set: launchAtLogin.setEnabled
                            )
                        )

                        if launchAtLogin.requiresApproval {
                            HStack {
                                Text(Localizer.text(.launchAtLoginApproval, language: settings.language))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(Localizer.text(.openLoginItems, language: settings.language)) {
                                    launchAtLogin.openSystemSettings()
                                }
                                .controlSize(.small)
                            }
                        }
                    }

                    persistenceSection

                    updatesSection
                }
                .padding(.trailing, 8)
            }

            footer
        }
        .padding(24)
        .frame(width: 580, height: 700)
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
            Localizer.text(.deletePersistedHistoryTitle, language: settings.language),
            isPresented: $showDeletePersistedHistoryConfirmation,
            titleVisibility: .visible
        ) {
            Button(Localizer.text(.delete, language: settings.language), role: .destructive) {
                clipboardStore.deletePersistedHistory()
            }
        } message: {
            Text(Localizer.text(.deletePersistedHistoryMessage, language: settings.language))
        }
    }

    private var updatesSection: some View {
        settingsSection(
            Localizer.text(.updates, language: settings.language),
            systemImage: "arrow.triangle.2.circlepath"
        ) {
            HStack(alignment: .center, spacing: 12) {
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

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(Localizer.text(.previousVersions, language: settings.language))
                    .font(.subheadline.weight(.medium))

                if updateManager.releases.isEmpty {
                    Text(Localizer.text(.noVersionsLoaded, language: settings.language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollView {
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
                                .padding(.vertical, 7)
                                if release.id != updateManager.releases.last?.id { Divider() }
                            }
                        }
                    }
                    .frame(height: 120)
                }
            }
        }
    }

    private var persistenceSection: some View {
        settingsSection(
            Localizer.text(.storage, language: settings.language),
            systemImage: "externaldrive"
        ) {
            toggleRow(
                Localizer.text(.persistHistory, language: settings.language),
                isOn: $settings.persistHistory
            )

            if settings.persistHistory {
                settingRow(Localizer.text(.historyFilePath, language: settings.language)) {
                    TextField("", text: $settings.historyFilePath)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 290)
                }

                settingRow(Localizer.text(.persistedHistoryLimit, language: settings.language)) {
                    Stepper(
                        value: $settings.maxPersistedHistoryItems,
                        in: settings.maxHistoryItems...AppSettings.maximumPersistedHistoryItems
                    ) {
                        Text("\(settings.maxPersistedHistoryItems)")
                            .monospacedDigit()
                            .frame(minWidth: 48, alignment: .trailing)
                    }
                    .frame(width: 130)
                }
            }

            HStack {
                Spacer()
                Button(Localizer.text(.deletePersistedHistory, language: settings.language), role: .destructive) {
                    showDeletePersistedHistoryConfirmation = true
                }
                .disabled(!clipboardStore.hasPersistedHistory)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "clipboard.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("ATO Clipboard Manager")
                    .font(.title2.weight(.semibold))
                Text(Localizer.text(.settingsDescription, language: settings.language))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Text(Localizer.text(.version, language: settings.language))
                .foregroundStyle(.secondary)

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

    private func settingsSection<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                content()
            }
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.08))
            }
        }
    }

    private func settingRow<Control: View>(
        _ title: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            control()
        }
        .frame(minHeight: 24)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 12)
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .frame(minHeight: 24)
    }
}
