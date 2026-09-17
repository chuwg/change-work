import WidgetKit

struct ChangeWidgetEntry: TimelineEntry {
    let date: Date
    let shiftType: ShiftType
    let shiftLabel: String
    let timeString: String
    let daysUntilOff: Int
    let weekShifts: [DayShift]
    /// The shift in progress or next up, as of [date].
    let nextEvent: ShiftEvent?
}
