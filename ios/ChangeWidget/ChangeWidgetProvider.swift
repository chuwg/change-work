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
        completion(buildEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChangeWidgetEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let allShifts = WidgetDataReader.readWeekShifts()

        var entries: [ChangeWidgetEntry] = []

        // Generate an entry for each day (today + next 6 days)
        // Each entry is scheduled at midnight of that day
        for dayOffset in 0..<7 {
            guard let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) else { continue }

            // Find the shift for this date from the stored week data
            let matchingShift = allShifts.first { shift in
                calendar.isDate(shift.date, inSameDayAs: entryDate)
            }

            let shiftType = matchingShift?.type ?? .none
            let shiftLabel = shiftType.label

            // Calculate time string from defaults for today, or from shift data
            let timeString: String
            if dayOffset == 0 {
                timeString = WidgetDataReader.readTimeString()
            } else {
                timeString = Self.defaultTimeString(for: shiftType)
            }

            // Calculate days until next off from this date
            let daysUntilOff = Self.daysUntilOff(from: dayOffset, shifts: allShifts, calendar: calendar, baseDate: now)

            // Build week shifts relative to this entry date
            let weekShifts = Self.buildRelativeWeekShifts(
                from: dayOffset, allShifts: allShifts, calendar: calendar, baseDate: now
            )

            let entry = ChangeWidgetEntry(
                date: entryDate,
                shiftType: shiftType,
                shiftLabel: shiftLabel,
                timeString: timeString,
                daysUntilOff: daysUntilOff,
                weekShifts: weekShifts
            )
            entries.append(entry)
        }

        // After 7 days, request a new timeline
        let refreshDate = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: now))!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    /// Build an entry for a specific date (used by snapshot)
    private func buildEntry(for date: Date) -> ChangeWidgetEntry {
        ChangeWidgetEntry(
            date: date,
            shiftType: WidgetDataReader.readTodayType(),
            shiftLabel: WidgetDataReader.readTodayLabel(),
            timeString: WidgetDataReader.readTimeString(),
            daysUntilOff: WidgetDataReader.readDaysUntilOff(),
            weekShifts: WidgetDataReader.readWeekShifts()
        )
    }

    /// Get default time string for a shift type
    private static func defaultTimeString(for type: ShiftType) -> String {
        switch type {
        case .day: return "06:00 - 14:00"
        case .evening: return "14:00 - 22:00"
        case .night: return "22:00 - 06:00"
        case .off, .none: return ""
        }
    }

    /// Calculate days until next off from a given day offset
    private static func daysUntilOff(from dayOffset: Int, shifts: [DayShift], calendar: Calendar, baseDate: Date) -> Int {
        for i in 1..<(shifts.count - dayOffset) {
            let idx = dayOffset + i
            if idx < shifts.count && shifts[idx].type == .off {
                return i
            }
        }
        return -1
    }

    /// Build week shifts array relative to a given day offset
    private static func buildRelativeWeekShifts(from dayOffset: Int, allShifts: [DayShift], calendar: Calendar, baseDate: Date) -> [DayShift] {
        var result: [DayShift] = []
        for i in 0..<7 {
            let idx = dayOffset + i
            if idx < allShifts.count {
                result.append(allShifts[idx])
            } else {
                // Beyond stored data — show as none
                let date = calendar.date(byAdding: .day, value: idx, to: calendar.startOfDay(for: baseDate))!
                result.append(DayShift(date: date, type: .none, label: "-"))
            }
        }
        return result
    }
}
