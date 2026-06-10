import SwiftUI

struct SettingsView: View {
    @AppStorage(AppStorageKey.theme)
    private var themeRawValue = AppTheme.system.rawValue

    @AppStorage(AppStorageKey.showProgress)
    private var showProgress = false

    @AppStorage(AppStorageKey.progressPosition)
    private var progressPositionRawValue = ProgressBarPosition.top.rawValue

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $themeRawValue) {
                    ForEach(AppTheme.allCases) { option in
                        Text(option.label).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Reading") {
                Toggle("Show reading progress", isOn: $showProgress)

                Picker("Progress bar position", selection: $progressPositionRawValue) {
                    ForEach(ProgressBarPosition.allCases) { option in
                        Text(option.label).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!showProgress)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
    }
}
