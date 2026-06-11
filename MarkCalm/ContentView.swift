import MarkdownUI
import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?

    @Environment(AppSettings.self) private var appSettings

    @State private var scrollProgress: CGFloat = 0

    private var baseURL: URL? {
        fileURL?.deletingLastPathComponent()
    }

    var body: some View {
        ZStack(alignment: appSettings.progressPosition == .top ? .top : .bottom) {
            TrackedScrollView(progress: $scrollProgress) {
                ReadingContent(
                    markdown: document.processed.body,
                    baseURL: baseURL
                )
            }

            if appSettings.showProgress {
                ProgressBar(value: scrollProgress)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: appSettings.progressPosition == .top ? .top : .bottom
                    )
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(document.displayName(for: fileURL))
        .preferredColorScheme(appSettings.theme.colorScheme)
        .defaultAppPrompt()
        .environment(\.openURL, OpenURLAction { url in
            NSWorkspace.shared.open(url)
            return .handled
        })
    }
}

private struct ProgressBar: View {
    let value: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.primary.opacity(0.1))

                Rectangle()
                    .fill(Color.accentColor.opacity(0.55))
                    .frame(width: geometry.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 3)
        .allowsHitTesting(false)
    }
}
