import WidgetKit

struct ShiftComplicationEntry: TimelineEntry {
    let date: Date
    let shiftType: ShiftType
    let shiftLabel: String
    let timeString: String
    let daysUntilOff: Int
    let nextEvent: ShiftEvent?
}

struct ShiftComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftComplicationEntry {
        ShiftComplicationEntry(
            date: Date(),
            shiftType: .day,
            shiftLabel: "주간",
            timeString: "06:00-14:00",
            daysUntilOff: 2,
            nextEvent: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftComplicationEntry) -> Void) {
        completion(readEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftComplicationEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let horizon: TimeInterval = 2 * 24 * 3600

        // Midnights change "today"; shift starts/ends flip the countdown from
        // 출근 to 퇴근. Between entries the relative text ticks on its own.
        let midnights = (1...2).compactMap {
            calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: now))
        }
        let boundaries = WidgetDataReader.shiftBoundaries(after: now, within: horizon)
        let dates = Array(Set([now] + midnights + boundaries)).sorted()

        let refresh = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: now))!
        completion(Timeline(entries: dates.map { readEntry(at: $0) }, policy: .after(refresh)))
    }

    private func readEntry(at date: Date) -> ShiftComplicationEntry {
        let start = WidgetDataReader.readTodayStart(at: date)
        let end = WidgetDataReader.readTodayEnd(at: date)
        let timeStr = (start.isEmpty || end.isEmpty) ? "" : "\(start)-\(end)"

        return ShiftComplicationEntry(
            date: date,
            shiftType: WidgetDataReader.readTodayType(at: date),
            shiftLabel: WidgetDataReader.readTodayLabel(at: date),
            timeString: timeStr,
            daysUntilOff: WidgetDataReader.readDaysUntilOff(at: date),
            nextEvent: WidgetDataReader.nextShiftEvent(at: date)
        )
    }
}
