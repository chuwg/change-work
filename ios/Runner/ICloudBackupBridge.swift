import Flutter
import Foundation

/// Reads and writes the backup file in the app's iCloud Drive container.
///
/// A file in the ubiquity container survives deleting the app and moving to a
/// new phone, which the on-device database does not. Everything here runs off
/// the main thread: resolving the container URL can block on first use.
final class ICloudBackupBridge: NSObject {
    static let shared = ICloudBackupBridge()

    private static let channelName = "com.change.app/icloud"
    private static let containerId = "iCloud.com.change.app.change"

    private let queue = DispatchQueue(label: "com.change.app.icloud", qos: .utility)

    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: Self.channelName, binaryMessenger: messenger)

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            let args = call.arguments as? [String: Any]
            let reply: (Any?) -> Void = { value in
                DispatchQueue.main.async { result(value) }
            }

            switch call.method {
            case "isAvailable":
                // Signed in to iCloud with iCloud Drive on for this app.
                self.queue.async { reply(self.documentsURL() != nil) }

            case "write":
                guard let name = args?["name"] as? String,
                      let contents = args?["contents"] as? String
                else { return reply(FlutterError(code: "bad_args", message: nil, details: nil)) }
                self.queue.async { reply(self.write(name: name, contents: contents)) }

            case "read":
                guard let name = args?["name"] as? String
                else { return reply(FlutterError(code: "bad_args", message: nil, details: nil)) }
                self.queue.async { reply(self.read(name: name)) }

            case "modifiedAt":
                guard let name = args?["name"] as? String
                else { return reply(FlutterError(code: "bad_args", message: nil, details: nil)) }
                self.queue.async { reply(self.modifiedAt(name: name)) }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func documentsURL() -> URL? {
        guard FileManager.default.ubiquityIdentityToken != nil,
              let root = FileManager.default.url(
                forUbiquityContainerIdentifier: Self.containerId)
        else { return nil }
        let docs = root.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: docs, withIntermediateDirectories: true)
        return docs
    }

    private func write(name: String, contents: String) -> Any {
        guard let url = documentsURL()?.appendingPathComponent(name) else {
            return FlutterError(code: "unavailable", message: "iCloud unavailable", details: nil)
        }
        var coordinatorError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(
            writingItemAt: url, options: .forReplacing, error: &coordinatorError
        ) { target in
            do {
                try contents.write(to: target, atomically: true, encoding: .utf8)
            } catch {
                writeError = error
            }
        }
        if let error = coordinatorError ?? writeError {
            return FlutterError(code: "write_failed", message: error.localizedDescription, details: nil)
        }
        return true
    }

    /// The file's contents, downloading it first if this device only has the
    /// iCloud placeholder (the usual case on a freshly set-up phone).
    private func read(name: String) -> Any? {
        guard let url = documentsURL()?.appendingPathComponent(name) else {
            return FlutterError(code: "unavailable", message: "iCloud unavailable", details: nil)
        }
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try? fm.startDownloadingUbiquitousItem(at: url)
            // Wait briefly for the download; a missing backup simply times out.
            for _ in 0..<40 where !fm.fileExists(atPath: url.path) {
                Thread.sleep(forTimeInterval: 0.25)
            }
        }
        guard fm.fileExists(atPath: url.path) else { return nil }

        var contents: String?
        var coordinatorError: NSError?
        NSFileCoordinator().coordinate(
            readingItemAt: url, options: [], error: &coordinatorError
        ) { target in
            contents = try? String(contentsOf: target, encoding: .utf8)
        }
        return contents
    }

    /// Milliseconds since epoch, or nil when there is no backup.
    private func modifiedAt(name: String) -> Any? {
        guard let docs = documentsURL() else { return nil }
        let url = docs.appendingPathComponent(name)
        // A not-yet-downloaded file exists only as ".name.icloud".
        let placeholder = docs.appendingPathComponent(".\(name).icloud")
        for candidate in [url, placeholder] {
            if let values = try? candidate.resourceValues(forKeys: [.contentModificationDateKey]),
               let date = values.contentModificationDate {
                return Int(date.timeIntervalSince1970 * 1000)
            }
        }
        return nil
    }
}
