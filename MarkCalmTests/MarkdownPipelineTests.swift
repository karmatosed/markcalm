import XCTest
@testable import MarkCalm

final class MarkdownPipelineTests: XCTestCase {
    func testStripsValidYAMLFrontmatter() {
        let input = "---\ntitle: Hello\n---\n\n# Body\n"
        let result = MarkdownPipeline.process(input)
        XCTAssertEqual(result.body, "# Body\n")
        XCTAssertTrue(result.hadFrontmatter)
    }

    func testLeavesInvalidFrontmatterUntouched() {
        let input = "---\n: bad yaml\n---\n\n# Body\n"
        let result = MarkdownPipeline.process(input)
        XCTAssertEqual(result.body, input)
        XCTAssertFalse(result.hadFrontmatter)
    }

    func testNoFrontmatterPassthrough() {
        let input = "# Hello\n"
        let result = MarkdownPipeline.process(input)
        XCTAssertEqual(result.body, input)
        XCTAssertFalse(result.hadFrontmatter)
    }
}
