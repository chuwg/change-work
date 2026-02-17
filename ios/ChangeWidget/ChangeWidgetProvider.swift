import WidgetKit

struct ChangeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChangeWidgetEntry {
        ChangeWidgetEntry(
            date: Date(),
            shiftType: .day,
            shiftLabel: "주간",
            timeString: "06:00 - 14:00",
            daysUntilOff: 2,
            weekShifts: WidgetDataReader.readWeekShifts()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ChangeWidgetEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChangeWidgetEntry>) -> Void) {
        let entry = readEntry()

        // Refresh at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func readEntry() -> ChangeWidgetEntry {
        ChangeWidgetEntry(
            date: Date(),
            shiftType: WidgetDataReader.readTodayType(),
            shiftLabel: WidgetDataReader.readTodayLabel(),
            timeString: WidgetDataReader.readTimeString(),
            daysUntilOff: WidgetDataReader.readDaysUntilOff(),
            weekShifts: WidgetDataReader.readWeekShifts()
        )
    }
}
