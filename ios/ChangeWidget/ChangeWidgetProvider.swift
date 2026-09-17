import WidgetKit

struct ChangeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChangeWidgetEntry {
        let now = Date()
        return ChangeWidgetEntry(
            date: now,
            shiftType: .day,
            shiftLabel: "주간",
            timeString: "06:00 - 14:00",
            daysUntilOff: 2,
            weekShifts: WidgetDataReader.readWeekShifts(),
            nextEvent: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ChangeWidgetEntry) -> Void) {
        completion(Self.entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChangeWidgetEntry>) -> Void) {
        let now = Date()
        let dates = Self.entryDates(from: now, days: 7)
        let entries = dates.map { Self.entry(at: $0) }

        let calendar = Calendar.current
        let refreshDate = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: now))!
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    /// Now, every midnight (today's shift / week strip change), and every
    /// shift start and end (the countdown flips between 출근 and 퇴근). The
    /// countdown text itself ticks on its own between entries.
    static func entryDates(from now: Date, days: Int) -> [Date] {
        let calendar = Calendar.current
        let midnights = (1..<days).compactMap {
            calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: now))
        }
        let boundaries = WidgetDataReader.shiftBoundaries(
            after: now, within: TimeInterval(days * 24 * 3600))
        return Array(Set([now] + midnights + boundaries)).sorted()
    }

    /// Everything the widget shows, resolved against [date] rather than the
    /// moment the timeline was built.
    static func entry(at date: Date) -> ChangeWidgetEntry {
        ChangeWidgetEntry(
            date: date,
            shiftType: WidgetDataReader.readTodayType(at: date),
            shiftLabel: WidgetDataReader.readTodayLabel(at: date),
            timeString: WidgetDataReader.readTimeString(at: date),
            daysUntilOff: WidgetDataReader.readDaysUntilOff(at: date),
            weekShifts: weekShifts(from: date),
            nextEvent: WidgetDataReader.nextShiftEvent(at: date)
        )
    }

    /// Seven days starting at [date], padded when the stored window runs out.
    private static func weekShifts(from date: Date) -> [DayShift] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let stored = WidgetDataReader.readWeekShifts()
        return (0..<7).map { i in
            let day = calendar.date(byAdding: .day, value: i, to: start)!
            return stored.first { calendar.isDate($0.date, inSameDayAs: day) }
                ?? DayShift(date: day, type: .none, label: "-")
        }
    }
}
