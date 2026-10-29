import XCTest
@testable import TranscriptCore

final class TranscriptTests: XCTestCase {
    func testAppleWordSpansAndAllParagraphs() throws {
        let xml = """
        <tt xmlns:podcasts="urn:podcasts" xmlns:ttm="urn:metadata"><body><p begin="2.740" ttm:agent="SPEAKER_1"><span podcasts:unit="sentence"><span podcasts:unit="word">Hello,</span><span podcasts:unit="word">world!</span></span><span podcasts:unit="sentence"><span podcasts:unit="word">A &amp; B.</span></span></p><p begin="48:13.000">The final words.</p></body></tt>
        """
        let transcript = try Transcript.parse(Data(xml.utf8))
        XCTAssertEqual(transcript.paragraphs.count, 2)
        XCTAssertEqual(transcript.text(), "Hello, world! A & B.\n\nThe final words.")
        XCTAssertEqual(transcript.paragraphs.first?.speaker, "SPEAKER_1")
        XCTAssertTrue(transcript.text(timestamps: true).hasSuffix("[48:13.000] The final words."))
        XCTAssertEqual(transcript.wordCount, 8)
    }
    func testStyledSpansDoNotSplitWords() throws {
        let transcript = try Transcript.parse(Data("<tt><body><p>Some <span>emphasized</span> text &amp; an en<span>tire</span> word.<br/>Next line.</p></body></tt>".utf8))
        XCTAssertEqual(transcript.text(), "Some emphasized text & an entire word. Next line.")
    }
    func testRejectsEmptyAndTruncatedFiles() {
        XCTAssertThrowsError(try Transcript.parse(Data("<tt><body/></tt>".utf8)))
        XCTAssertThrowsError(try Transcript.parse(Data("<tt><p>Partial</p><p>missing".utf8)))
    }
}
