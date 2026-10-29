import XCTest
@testable import TranscriptCore

final class LibraryTests: XCTestCase {
    func testDiscoveryPreservesUnmatchedFilesAndLoadsCompleteText() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let nested = root.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try Data("<tt><body><p>First.</p><p>Last.</p></body></tt>".utf8)
            .write(to: nested.appendingPathComponent("transcript_123.ttml-123.ttml"))
        try Data("<tt><body><p>Other.</p></body></tt>".utf8)
            .write(to: root.appendingPathComponent("custom.ttml"))
        try Data().write(to: root.appendingPathComponent("audio.mp3"))
        let scan = try PodcastLibrary.scan(root: root)
        XCTAssertEqual(scan.episodes.count, 2)
        XCTAssertTrue(scan.warnings.isEmpty)
        let episode = try XCTUnwrap(scan.episodes.first { $0.title == "Episode 123" })
        XCTAssertEqual(try episode.load().text(), "First.\n\nLast.")
        XCTAssertTrue(scan.episodes.contains { $0.title == "custom" })
    }
    func testMissingFolderIsAnError() {
        XCTAssertThrowsError(try PodcastLibrary.scan(root: URL(fileURLWithPath: "/missing-\(UUID().uuidString)")))
    }
    func testIdentifierUsesExactFilenamePattern() {
        XCTAssertEqual(PodcastLibrary.episodeID(from: "transcript_1000797898056.ttml-1000797898056.ttml"), "1000797898056")
        XCTAssertNil(PodcastLibrary.episodeID(from: "other_123.ttml"))
    }
}
