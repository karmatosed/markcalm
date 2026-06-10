import SwiftUI

@main
struct MarkCalmApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { configuration in
            ContentView(
                document: configuration.$document,
                fileURL: configuration.fileURL
            )
        }
        .defaultSize(width: 800, height: 900)

        Settings {
            SettingsView()
        }
    }
}
