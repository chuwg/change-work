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

    /// Queue a shift change made on the watch for the phone to apply.
    ///
    /// Same one-way channel the energy records use: the watch has no database
    /// of its own, so it appends to a pending list in the shared App Group and
    /// the phone drains it on its next sync.
    static func writeShiftChange(date: Date, type: String) {
        var pending = readPendingShiftChanges()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)

        // One entry per day: a second edit of the same date replaces the first
        // rather than making the phone apply both in arrival order.
        pending.removeAll { ($0["date"] as? String) == dateKey }
        pending.append([
            "date": dateKey,
            "type": type,
            "changed_at": ISO8601DateFormatter().string(from: Date()),
        ])

        if let data = try? JSONSerialization.data(withJSONObject: pending),
           let jsonString = String(data: data, encoding: .utf8) {
            defaults?.set(jsonString, forKey: "watch_shift_pending")
        }

        // Reflect the change locally so the watch does not look unchanged
        // while it waits for the phone.
        WatchScheduleStore.shared.applyLocalShiftChange(date: date, type: type)
    }

    static func readPendingShiftChanges() -> [[String: Any]] {
        guard let jsonString = defaults?.string(forKey: "watch_shift_pending"),
              let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data)
                as? [[String: Any]]
        else { return [] }
        return array
    }

    static func readPendingRecords() -> [[String: Any]] {
        guard let jsonString = defaults?.string(forKey: "watch_energy_pending"),
              let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        return array
    }
}
