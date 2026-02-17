import WidgetKit

struct ShiftComplicationEntry: TimelineEntry {
    let date: Date
    let shiftType: ShiftType
    let shiftLabel: String
    let timeString: String
    let daysUntilOff: Int
}

struct ShiftComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftComplicationEntry {
        ShiftComplicationEntry(
            date: Date(),
            shiftType: .day,
            shiftLabel: "주간",
            timeString: "06:00-14:00",
            daysUntilOff: 2
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShiftComplicationEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftComplicationEntry>) -> Void) {
        let entry = readEntry()

        // Refresh at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: Date())!
        )
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func readEntry() -> ShiftComplicationEntry {
        let start = WidgetDataReader.readTodayStart()
        let end = WidgetDataReader.readTodayEnd()
        let timeStr = (start.isEmpty || end.isEmpty) ? "" : "\(start)-\(end)"

        return ShiftComplicationEntry(
            date: Date(),
            shiftType: WidgetDataReader.readTodayType(),
            shiftLabel: WidgetDataReader.readTodayLabel(),
            timeString: timeStr,
            daysUntilOff: WidgetDataReader.readDaysUntilOff()
        )
    }
}
