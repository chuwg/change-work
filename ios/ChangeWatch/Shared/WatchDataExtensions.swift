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
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
