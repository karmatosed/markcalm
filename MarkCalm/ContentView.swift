import MarkdownUI
import SwiftUI

@MainActor
@Observable
final class ScrollProgress {
    var value: CGFloat = 0
}

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

private struct ScrollContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Isolates scroll progress so progress updates do not re-render the scroll view.
private struct ReadingScrollView: View {
    let markdown: String
    let baseURL: URL?
    let showProgress: Bool
    let progressPosition: ProgressBarPosition

    @State private var scrollProgress = ScrollProgress()
    @State private var contentHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            if showProgress, progressPosition == .top {
                ProgressIndicator(progress: scrollProgress)
            }

            ScrollView {
                ReadingContent(
                    markdown: markdown,
                    baseURL: baseURL
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ScrollContentHeightKey.self,
                                value: geometry.size.height
                            )
                            .preference(
                                key: ScrollOffsetKey.self,
                                value: geometry.frame(in: .named("readingScroll")).minY
                            )
                    }
                }
            }
            .coordinateSpace(name: "readingScroll")
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            viewportHeight = geometry.size.height
                            updateScrollProgress()
                        }
                        .onChange(of: geometry.size.height) { _, height in
                            viewportHeight = height
                            updateScrollProgress()
                        }
                }
            }
            .onPreferenceChange(ScrollContentHeightKey.self) { height in
                contentHeight = height
                updateScrollProgress()
            }
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                scrollOffset = offset
                updateScrollProgress()
            }

            if showProgress, progressPosition == .bottom {
                ProgressIndicator(progress: scrollProgress)
            }
        }
        .id(markdown)
    }

    private func updateScrollProgress() {
        let scrollable = contentHeight - viewportHeight
        guard scrollable > 1 else {
            scrollProgress.value = 1
            return
        }

        scrollProgress.value = min(max(-scrollOffset / scrollable, 0), 1)
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
