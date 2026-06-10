import Foundation
import Yams

struct ProcessedMarkdown: Equatable {
    let body: String
    let hadFrontmatter: Bool
}

enum MarkdownPipeline {
    static func process(_ raw: String) -> ProcessedMarkdown {
        guard raw.hasPrefix("---") else {
            return ProcessedMarkdown(body: raw, hadFrontmatter: false)
        }

        let lines = raw.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count >= 2 else {
            return ProcessedMarkdown(body: raw, hadFrontmatter: false)
        }

        var endIndex: Int?
        for index in 1..<lines.count where lines[index] == "---" {
            endIndex = index
            break
        }

        guard let endIndex else {
            return ProcessedMarkdown(body: raw, hadFrontmatter: false)
        }

        let yaml = lines[1..<endIndex].joined(separator: "\n")
        do {
            _ = try Yams.load(yaml: yaml)
        } catch {
            return ProcessedMarkdown(body: raw, hadFrontmatter: false)
        }

        let bodyStart = lines.index(after: endIndex)
        let body = lines[bodyStart...].joined(separator: "\n")
        return ProcessedMarkdown(body: body, hadFrontmatter: true)
    }
}
