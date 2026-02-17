import Foundation

class WatchDataWriter {
    static let appGroupId = "group.com.change.app.change"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static func writeEnergyRecord(level: Int) {
        var pending = readPendingRecords()
        let record: [String: Any] = [
            "energy_level": level,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "source": "watch"
        ]
        pending.append(record)

        if let data = try? JSONSerialization.data(withJSONObject: pending),
           let jsonString = String(data: data, encoding: .utf8) {
            defaults?.set(jsonString, forKey: "watch_energy_pending")
        }

        // Update live value so Watch UI reflects immediately
        defaults?.set(level, forKey: "widget_energy_latest")
    }

    static func readPendingRecords() -> [[String: Any]] {
        guard let jsonString = defaults?.string(forKey: "watch_energy_pending"),
              let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        return array
    }
}
