import MarkdownUI
import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?

    @Environment(AppSettings.self) private var appSettings

    private var baseURL: URL? {
        fileURL?.deletingLastPathComponent()
    }

    var body: some View {
        ReadingScrollView(
            markdown: document.processed.body,
            baseURL: baseURL,
            showProgress: appSettings.showProgress,
            progressPosition: appSettings.progressPosition
        )
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

/// Isolates scroll progress so progress updates do not re-render the scroll view.
private struct ReadingScrollView: View {
    let markdown: String
    let baseURL: URL?
    let showProgress: Bool
    let progressPosition: ProgressBarPosition

    @State private var scrollProgress = ScrollProgress()

    var body: some View {
        VStack(spacing: 0) {
            if showProgress, progressPosition == .top {
                ProgressIndicator(progress: scrollProgress)
            }

            TrackedScrollView(progress: scrollProgress) {
                ReadingContent(
                    markdown: markdown,
                    baseURL: baseURL
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showProgress, progressPosition == .bottom {
                ProgressIndicator(progress: scrollProgress)
            }
        }
        .id(markdown)
    }
}

private struct ProgressIndicator: View {
    let progress: ScrollProgress

    var body: some View {
        ProgressBar(value: progress.value)
    }
}

private struct ProgressBar: View {
    let value: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.primary.opacity(0.15))

                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 4)
        .allowsHitTesting(false)
    }
}
