import MarkdownUI
import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?

    @AppStorage(AppStorageKey.theme)
    private var themeRawValue = AppTheme.system.rawValue

    @AppStorage(AppStorageKey.showProgress)
    private var showProgress = false

    @AppStorage(AppStorageKey.progressPosition)
    private var progressPositionRawValue = ProgressBarPosition.top.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: themeRawValue) ?? .system
    }

    @State private var scrollProgress: CGFloat = 0

    private var progressPosition: ProgressBarPosition {
        ProgressBarPosition(rawValue: progressPositionRawValue) ?? .top
    }

    private var baseURL: URL? {
        fileURL?.deletingLastPathComponent()
    }

    var body: some View {
        ZStack(alignment: progressPosition == .top ? .top : .bottom) {
            TrackedScrollView(progress: $scrollProgress) {
                ReadingContent(
                    markdown: document.processed.body,
                    baseURL: baseURL
                )
            }

            if showProgress {
                ProgressBar(value: scrollProgress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: progressPosition == .top ? .top : .bottom)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(document.displayName(for: fileURL))
        .preferredColorScheme(theme.colorScheme)
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
