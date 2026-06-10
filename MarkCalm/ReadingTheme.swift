import MarkdownUI
import SwiftUI

enum ReadingTheme {
    static var calm: Theme {
        Theme.gitHub
            .text {
                BackgroundColor(nil)
            }
    }
}

struct ReadingContent: View {
    let markdown: String
    let baseURL: URL?

    var body: some View {
        Markdown(markdown, baseURL: baseURL, imageBaseURL: baseURL)
            .markdownTheme(ReadingTheme.calm)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
            .padding(.vertical, 48)
            .textSelection(.enabled)
    }
}
