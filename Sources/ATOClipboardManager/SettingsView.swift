import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 16) {
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                GridRow {
                    Text(Localizer.text(.language, language: settings.language))
                    Picker("", selection: $settings.language) {
                        ForEach(AppLanguage.allCases) { language in Text(language.displayName).tag(language) }
                    }.labelsHidden().frame(width: 150)
                }
                GridRow {
                    Text(Localizer.text(.displayMode, language: settings.language))
                    Picker("", selection: $settings.displayMode) {
                        Text(Localizer.text(.grid, language: settings.language)).tag(DisplayMode.grid)
                        Text(Localizer.text(.list, language: settings.language)).tag(DisplayMode.list)
                    }.labelsHidden().frame(width: 150)
                }
                GridRow {
                    Text(Localizer.text(.maxHistory, language: settings.language))
                    Stepper(value: $settings.maxHistoryItems, in: 1...100) { Text("\(settings.maxHistoryItems)") }
                        .frame(width: 150)
                }
            }

            Toggle(Localizer.text(.automaticPaste, language: settings.language), isOn: $settings.automaticPaste)
            Toggle(Localizer.text(.automaticPasteShortcut, language: settings.language), isOn: $settings.automaticPasteShortcut)
            Divider()
            HStack {
                Link(destination: URL(string: "https://github.com/simonepiteo/ato-clipboard-manager")!) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/simonepiteo/ato-clipboard-manager/blob/main/LICENSE")!) {
                    Image(systemName: "doc.text")
                }
                Text(Localizer.text(.version, language: settings.language)).foregroundStyle(.secondary)
                Spacer()
                Button(Localizer.text(.resetSettings, language: settings.language), action: settings.reset)
            }
        }
        .padding(22)
        .frame(width: 440, height: 310)
    }
}
