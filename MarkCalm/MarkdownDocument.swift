import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.markdown, UTType(filenameExtension: "md")!, .plainText]
    }

    var rawContent: String

    init(text: String = "") {
        rawContent = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        rawContent = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(rawContent.utf8))
    }

    var processed: ProcessedMarkdown {
        MarkdownPipeline.process(rawContent)
    }

    func displayName(for fileURL: URL?) -> String {
        fileURL?.deletingPathExtension().lastPathComponent ?? "Untitled"
    }
}

private extension UTType {
    static var markdown: UTType {
        UTType(importedAs: "net.daringfireball.markdown")
    }
}
