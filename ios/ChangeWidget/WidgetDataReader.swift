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
    let start: String
    let end: String

    init(date: Date, type: ShiftType, label: String,
         start: String = "", end: String = "") {
        self.date = date
        self.type = type
        self.label = label
        self.start = start
        self.end = end
    }
}

class WidgetDataReader {
    static let appGroupId = "group.com.change.app.change"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    /// Today's shift, resolved by *date*.
    ///
    /// The `widget_today_*` keys are a snapshot frozen at whatever moment the
    /// phone app last ran — they carry no date, so after midnight they still
    /// describe yesterday. The week list is dated, so matching today against it
    /// keeps the widget, the watch app and the complication correct across a
    /// day rollover even if the phone is never opened. The flat keys remain as
    /// a fallback for data written by an older build.
    static func readTodayShift() -> DayShift? {
        guard let week = storedWeekShifts() else { return nil }
        let today = Date()
        return week.first {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }

    static func readTodayType() -> ShiftType {
        if let today = readTodayShift() { return today.type }
        guard let raw = defaults?.string(forKey: "widget_today_shift_type") else {
            return .none
        }
        return ShiftType(rawValue: raw) ?? .none
    }

    static func readTodayLabel() -> String {
        if let today = readTodayShift() { return today.label }
        return defaults?.string(forKey: "widget_today_shift_label") ?? "미등록"
    }

    static func readTodayStart() -> String {
        if let today = readTodayShift(), !today.start.isEmpty {
            return today.start
        }
        return defaults?.string(forKey: "widget_today_shift_start") ?? ""
    }

    static func readTodayEnd() -> String {
        if let today = readTodayShift(), !today.end.isEmpty {
            return today.end
        }
        return defaults?.string(forKey: "widget_today_shift_end") ?? ""
    }

    /// Days until the next off day, counted from the dated week list so it too
    /// survives a day rollover. -1 means "none within the stored window".
    static func readDaysUntilOff() -> Int {
        if let week = storedWeekShifts() {
            let today = Calendar.current.startOfDay(for: Date())
            for entry in week where entry.type == .off {
                let day = Calendar.current.startOfDay(for: entry.date)
                guard let diff = Calendar.current.dateComponents(
                    [.day], from: today, to: day
                ).day, diff > 0 else { continue }
                return diff
            }
            return -1
        }
        return defaults?.integer(forKey: "widget_days_until_off") ?? -1
    }

    static func readWeekShifts() -> [DayShift] {
        storedWeekShifts() ?? generatePlaceholderWeek()
    }

    /// The stored schedule, or nil when nothing has been written yet.
    ///
    /// Kept separate from `readWeekShifts()` on purpose: the placeholder week
    /// is all-`.none` with today's date in it, so resolving today against it
    /// would report "미등록" instead of letting the legacy keys answer.
    private static func storedWeekShifts() -> [DayShift]? {
        guard let jsonString = defaults?.string(forKey: "widget_week_shifts"),
              let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: String]],
              !array.isEmpty
        else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // Fixed locale/calendar: the device may be on a non-Gregorian calendar,
        // which would otherwise misparse these dates and break the day match.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)

        return array.map { item in
            let date = formatter.date(from: item["date"] ?? "") ?? Date()
            let type = ShiftType(rawValue: item["type"] ?? "none") ?? .none
            let label = item["label"] ?? "-"
            // start/end are absent in data written by older builds.
            return DayShift(
                date: date,
                type: type,
                label: label,
                start: item["start"] ?? "",
                end: item["end"] ?? ""
            )
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
