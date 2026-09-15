import Combine
import Foundation

/// Why the watch has nothing to show.
enum ScheduleAvailability {
    /// The phone has never written to the shared container.
    case neverSynced
    /// The phone has synced, but today has no shift on it.
    case noShiftToday
    /// There is a shift to show.
    case available
}

/// The watch's view of the schedule, and the only thing the views read.
///
/// The views used to call `WidgetDataReader` straight from `let` properties,
/// which froze whatever the shared container held the instant each view struct
/// was built. If the watch app opened before the phone had ever written, it
/// showed "미등록" and stayed that way even after the phone synced — the only
/// way out was force-quitting the app.
///
/// Publishing the data instead means a `refresh()` on appear and on activation
/// actually updates the screen.
final class WatchScheduleStore: ObservableObject {
    static let shared = WatchScheduleStore()

    @Published private(set) var today: DayShift?
    @Published private(set) var week: [DayShift] = []
    @Published private(set) var daysUntilOff: Int = -1
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var availability: ScheduleAvailability = .neverSynced

    private init() {
        refresh()
    }

    func refresh() {
        let week = WidgetDataReader.readWeekShifts()
        let today = WidgetDataReader.readTodayShift()
        let updated = WidgetDataReader.readLastUpdated()

        self.week = week
        self.today = today
        self.daysUntilOff = WidgetDataReader.readDaysUntilOff()
        self.lastUpdated = updated

        if updated == nil && today == nil {
            availability = .neverSynced
        } else if today == nil || today?.type == ShiftType.none {
            availability = .noShiftToday
        } else {
            availability = .available
        }
    }

    /// Show a change made on the watch immediately, before the phone has had a
    /// chance to apply it and write the schedule back.
    func applyLocalShiftChange(date: Date, type: String) {
        guard let shiftType = ShiftType(rawValue: type) else { return }
        let calendar = Calendar.current
        let times = Self.defaultTimes(for: shiftType)

        week = week.map { day in
            guard calendar.isDate(day.date, inSameDayAs: date) else { return day }
            return DayShift(
                date: day.date,
                type: shiftType,
                label: shiftType.label,
                start: times.start,
                end: times.end
            )
        }

        if calendar.isDateInToday(date) {
            today = DayShift(
                date: date,
                type: shiftType,
                label: shiftType.label,
                start: times.start,
                end: times.end
            )
            availability = .available
        }
        objectWillChange.send()
    }

    /// The phone owns the real (user-customisable) shift times; these are only
    /// used to fill in the optimistic update until it syncs back.
    private static func defaultTimes(for type: ShiftType) -> (start: String, end: String) {
        switch type {
        case .day: return ("06:00", "14:00")
        case .evening: return ("14:00", "22:00")
        case .night: return ("22:00", "06:00")
        case .off, .none: return ("", "")
        }
    }
}
