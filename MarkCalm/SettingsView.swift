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

            Section("Reading") {
                Toggle("Show reading progress", isOn: $appSettings.showProgress)

                Picker("Progress bar position", selection: $appSettings.progressPosition) {
                    ForEach(ProgressBarPosition.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!appSettings.showProgress)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}
