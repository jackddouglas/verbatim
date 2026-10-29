import Foundation
import SQLite3

public struct Episode: Identifiable, Sendable {
    public var id: URL { file }
    public let file: URL
    public let title: String
    public let show: String
    public let modified: Date
    public func load() throws -> Transcript { try Transcript.parse(Data(contentsOf: file)) }
}

public struct LibraryScan: Sendable {
    public let episodes: [Episode]
    public let warnings: [String]
}

public enum PodcastLibrary {
    public static var defaultRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Group Containers/243LU875E5.groups.com.apple.podcasts")
    }

    public static func scan(root: URL = defaultRoot) throws -> LibraryScan {
        let manager = FileManager.default
        // A selected folder may also be a standalone collection of TTML files.
        let appleCache = root.appendingPathComponent("Library/Cache/Assets/TTML")
        let directory = manager.fileExists(atPath: appleCache.path) ? appleCache : root
        _ = try manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        var warnings: [String] = []
        var metadata: [String: (String, String)] = [:]
        let database = root.appendingPathComponent("Documents/MTLibrary.sqlite")
        if manager.fileExists(atPath: database.path) {
            do { metadata = try readMetadata(database) }
            catch { warnings.append("Episode titles could not be loaded. Transcripts are listed by filename. \(error.localizedDescription)") }
        }
        guard let enumerator = manager.enumerator(at: directory, includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey], options: [.skipsHiddenFiles], errorHandler: { url, error in
            warnings.append("Could not read \(url.lastPathComponent): \(error.localizedDescription)")
            return true
        }) else { throw CocoaError(.fileReadNoPermission) }
        var episodes: [Episode] = []
        for case let file as URL in enumerator where file.pathExtension.lowercased() == "ttml" {
            let values = try file.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey])
            guard values.isRegularFile == true else { continue }
            let identifier = episodeID(from: file.lastPathComponent)
            let info = identifier.flatMap { metadata[$0] }
            episodes.append(Episode(file: file, title: info?.0 ?? identifier.map { "Episode \($0)" } ?? file.deletingPathExtension().lastPathComponent,
                                    show: info?.1 ?? "Cached transcript", modified: values.contentModificationDate ?? .distantPast))
        }
        return LibraryScan(episodes: episodes.sorted { $0.modified > $1.modified }, warnings: warnings)
    }

    public static func episodeID(from filename: String) -> String? {
        guard let range = filename.range(of: #"transcript_([0-9]+)\.ttml"#, options: .regularExpression) else { return nil }
        return String(filename[range]).replacingOccurrences(of: "transcript_", with: "").replacingOccurrences(of: ".ttml", with: "")
    }

    private static func readMetadata(_ url: URL) throws -> [String: (String, String)] {
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            if let db { sqlite3_close(db) }
            throw CocoaError(.fileReadNoPermission)
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, 1000)
        var statement: OpaquePointer?
        let query = "SELECT e.ZSTORETRACKID, e.ZTITLE, p.ZTITLE FROM ZMTEPISODE e LEFT JOIN ZMTPODCAST p ON e.ZPODCAST = p.Z_PK WHERE e.ZSTORETRACKID > 0"
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "Verbatim", code: 1, userInfo: [NSLocalizedDescriptionKey: "The Podcasts database format is not supported."])
        }
        defer { sqlite3_finalize(statement) }
        var result: [String: (String, String)] = [:]
        var status = sqlite3_step(statement)
        while status == SQLITE_ROW {
            let id = String(sqlite3_column_int64(statement, 0))
            let title = sqlite3_column_text(statement, 1).map { String(cString: $0) } ?? "Episode \(id)"
            let show = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? "Apple Podcasts"
            result[id] = (title, show)
            status = sqlite3_step(statement)
        }
        guard status == SQLITE_DONE else { throw CocoaError(.fileReadUnknown) }
        return result
    }
}
