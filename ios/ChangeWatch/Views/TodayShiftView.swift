import SwiftUI

struct TodayShiftView: View {
    private let shiftType = WidgetDataReader.readTodayType()
    private let shiftLabel = WidgetDataReader.readTodayLabel()
    private let timeString = WidgetDataReader.readTimeString()
    private let daysUntilOff = WidgetDataReader.readDaysUntilOff()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Shift icon + label
            HStack(spacing: 8) {
                Image(systemName: shiftType.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(shiftType.color)

                Text(shiftLabel)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            // Time
            if !timeString.isEmpty {
                Text(timeString)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(white: 0.6))
            }

            Spacer()

            // Days until off
            if shiftType == .off {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ShiftType.off.color)
                    Text("오늘 휴무")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ShiftType.off.color)
                }
            } else if daysUntilOff > 0 {
                HStack(spacing: 6) {
                    Text("휴무까지")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))
                    Text("D-\(daysUntilOff)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ShiftType.off.color)
                }
            }

            // Last updated
            if let updated = WidgetDataReader.readLastUpdated() {
                let formatter = RelativeDateTimeFormatter()
                Text(formatter.localizedString(for: updated, relativeTo: Date()))
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.35))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.1, green: 0.08, blue: 0.07))
    }
}
