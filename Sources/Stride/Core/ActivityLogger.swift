import Foundation

/**
 Lightweight JSONL activity logger.

 This is intentionally simple: every time Stride starts a new session
 (app/window context change), we append one JSON line with a timestamp.

 File location:
   ~/Library/Application Support/Stride/activity.jsonl
 */
final class ActivityLogger {
    static let shared = ActivityLogger()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder

    private init() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    struct ActivityEvent: Codable {
        let timestamp: Date
        let appName: String
        let windowTitle: String
    }

    func log(appName: String, windowTitle: String) {
        let event = ActivityEvent(timestamp: Date(), appName: appName, windowTitle: windowTitle)

        guard let data = try? encoder.encode(event) else { return }
        guard let folderURL = Self.applicationSupportStrideFolderURL() else { return }

        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let fileURL = folderURL.appendingPathComponent("activity.jsonl")

            if !fileManager.fileExists(atPath: fileURL.path) {
                fileManager.createFile(atPath: fileURL.path, contents: nil)
            }

            let handle = try FileHandle(forWritingTo: fileURL)
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.write(contentsOf: Data("\n".utf8))
            try handle.close()
        } catch {
            // Best-effort logging: avoid impacting the tracking loop.
        }
    }

    static func applicationSupportStrideFolderURL() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Stride", isDirectory: true)
    }
}
