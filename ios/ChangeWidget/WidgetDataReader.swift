import Foundation
import SwiftUI

enum ShiftType: String {
    case day
    case evening
    case night
    case off
    case none

    var label: String {
        switch self {
        case .day: return "주간"
        case .evening: return "오후"
        case .night: return "야간"
        case .off: return "휴무"
        case .none: return "미등록"
        }
    }

    var color: Color {
        switch self {
        case .day: return Color(red: 1.0, green: 0.72, blue: 0.25)
        case .evening: return Color(red: 1.0, green: 0.42, blue: 0.21)
        case .night: return Color(red: 0.45, green: 0.39, blue: 0.94)
        case .off: return Color(red: 0.37, green: 0.73, blue: 0.51)
        case .none: return Color(white: 0.4)
        }
    }

    var icon: String {
        switch self {
        case .day: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        case .off: return "house.fill"
        case .none: return "questionmark.circle"
        }
    }

    var shortLabel: String {
        switch self {
        case .day: return "주"
        case .evening: return "오"
        case .night: return "야"
        case .off: return "휴"
        case .none: return "-"
        }
    }
}

struct DayShift: Identifiable {
    let id = UUID()
    let date: Date
    let type: ShiftType
    let label: String
}

class WidgetDataReader {
    static let appGroupId = "group.com.change.app.change"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static func readTodayType() -> ShiftType {
        guard let raw = defaults?.string(forKey: "widget_today_shift_type") else {
            return .none
        }
        return ShiftType(rawValue: raw) ?? .none
    }

    static func readTodayLabel() -> String {
        defaults?.string(forKey: "widget_today_shift_label") ?? "미등록"
    }

    static func readTodayStart() -> String {
        defaults?.string(forKey: "widget_today_shift_start") ?? ""
    }

    static func readTodayEnd() -> String {
        defaults?.string(forKey: "widget_today_shift_end") ?? ""
    }

    static func readDaysUntilOff() -> Int {
        defaults?.integer(forKey: "widget_days_until_off") ?? -1
    }

    static func readWeekShifts() -> [DayShift] {
        guard let jsonString = defaults?.string(forKey: "widget_week_shifts"),
              let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
        else {
            return generatePlaceholderWeek()
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return array.map { item in
            let date = formatter.date(from: item["date"] ?? "") ?? Date()
            let type = ShiftType(rawValue: item["type"] ?? "none") ?? .none
            let label = item["label"] ?? "-"
            return DayShift(date: date, type: type, label: label)
        }
    }

    static func readTimeString() -> String {
        let start = readTodayStart()
        let end = readTodayEnd()
        if start.isEmpty || end.isEmpty { return "" }
        return "\(start) - \(end)"
    }

    private static func generatePlaceholderWeek() -> [DayShift] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { i in
            let date = calendar.date(byAdding: .day, value: i, to: today)!
            return DayShift(date: date, type: .none, label: "-")
        }
    }
}
