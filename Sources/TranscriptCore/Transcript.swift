import Foundation

public struct Paragraph: Sendable, Equatable {
    public let text: String
    public let start: String?
    public let speaker: String?
}

public enum TranscriptError: LocalizedError {
    case invalidXML(String)
    case empty
    public var errorDescription: String? {
        switch self {
        case .invalidXML(let detail): "The transcript could not be read: \(detail)"
        case .empty: "This file contains no transcript paragraphs."
        }
    }
}

public struct Transcript: Sendable {
    public let paragraphs: [Paragraph]
    public var wordCount: Int { paragraphs.reduce(0) { $0 + $1.text.split(whereSeparator: \.isWhitespace).count } }
    public func text(timestamps: Bool = false) -> String {
        paragraphs.map { paragraph in
            let prefix = timestamps ? paragraph.start.map { "[\($0)] " } ?? "" : ""
            return prefix + paragraph.text
        }.joined(separator: "\n\n")
    }
    public static func parse(_ data: Data) throws -> Transcript {
        let delegate = TTMLParser()
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        guard parser.parse() else { throw TranscriptError.invalidXML(parser.parserError?.localizedDescription ?? "Invalid XML") }
        guard !delegate.paragraphs.isEmpty else { throw TranscriptError.empty }
        return Transcript(paragraphs: delegate.paragraphs)
    }
}

private final class TTMLParser: NSObject, XMLParserDelegate {
    var paragraphs: [Paragraph] = []
    private var buffer: String?
    private var start: String?
    private var speaker: String?
    private var wordDepth: Int?
    private var depth = 0

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
        depth += 1
        let name = elementName.split(separator: ":").last.map(String.init) ?? elementName
        if name == "p" {
            buffer = ""
            start = attributes["begin"]
            speaker = attributes.first { $0.key == "agent" || $0.key.hasSuffix(":agent") }?.value
        } else if buffer != nil {
            if name == "br" { buffer?.append("\n") }
            if attributes.contains(where: { ($0.key == "unit" || $0.key.hasSuffix(":unit")) && $0.value == "word" }) {
                if let last = buffer?.last, !last.isWhitespace { buffer?.append(" ") }
                wordDepth = depth
            }
        }
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if buffer != nil { buffer?.append(string) }
    }
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        let name = elementName.split(separator: ":").last.map(String.init) ?? elementName
        if name == "p", let buffer {
            let text = buffer.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            if !text.isEmpty { paragraphs.append(Paragraph(text: text, start: start, speaker: speaker)) }
            self.buffer = nil
        }
        if wordDepth == depth {
            buffer?.append(" ")
            wordDepth = nil
        }
        depth -= 1
    }
}
