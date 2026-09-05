import Foundation

extension WidgetDataReader {
    static func readLatestEnergyLevel() -> Int {
        defaults?.integer(forKey: "widget_energy_latest") ?? 0
    }

    static func readAverageEnergy() -> Double {
        defaults?.double(forKey: "widget_energy_avg") ?? 0
    }

    static func readSleepHours() -> Double {
        defaults?.double(forKey: "widget_sleep_hours") ?? 0
    }

    static func readSleepQuality() -> Int {
        defaults?.integer(forKey: "widget_sleep_quality") ?? 0
    }

    static func readLastUpdated() -> Date? {
        guard let str = defaults?.string(forKey: "widget_last_updated") else { return nil }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: str) { return date }
        if let date = ISO8601DateFormatter().date(from: str) { return date }

        // The phone writes Dart's `DateTime.now().toIso8601String()`, which
        // carries no timezone designator — ISO8601DateFormatter rejects those,
        // so the "last updated" line never appeared. Parse it as local time.
        let local = DateFormatter()
        local.locale = Locale(identifier: "en_US_POSIX")
        local.calendar = Calendar(identifier: .gregorian)
        local.timeZone = .current
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                       "yyyy-MM-dd'T'HH:mm:ss.SSS",
                       "yyyy-MM-dd'T'HH:mm:ss"] {
            local.dateFormat = format
            if let date = local.date(from: str) { return date }
        }
        return nil
    }
}
