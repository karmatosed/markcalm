import SwiftUI

@main
struct MarkCalmApp: App {
    @State private var appSettings = AppSettings.shared

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { configuration in
            ContentView(
                document: configuration.$document,
                fileURL: configuration.fileURL
            )
            .environment(appSettings)
        }
        .defaultSize(width: 800, height: 900)

        Settings {
            SettingsView()
                .environment(appSettings)
        }
    }
}
