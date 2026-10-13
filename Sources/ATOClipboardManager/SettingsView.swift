import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var launchAtLogin: LaunchAtLoginManager

    var body: some View {
        VStack(spacing: 20) {
            header

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

            footer
        }
        .padding(24)
        .frame(width: 520, height: 540)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear(perform: launchAtLogin.refresh)
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
