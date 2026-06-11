import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        @Bindable var appSettings = appSettings

        Form {
            Section("Appearance") {
                Picker("Theme", selection: $appSettings.theme) {
                    ForEach(AppTheme.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle("Show reading progress", isOn: $appSettings.showProgress)

                Picker("Progress bar position", selection: $appSettings.progressPosition) {
                    ForEach(ProgressBarPosition.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!appSettings.showProgress)
            } header: {
                Text("Reading")
            } footer: {
                Text("Turn on “Show reading progress” to display the bar. Position only applies when it is enabled.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}
