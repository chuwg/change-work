import SwiftUI
import WidgetKit

struct WeekWidgetView: View {
    let entry: ChangeWidgetEntry

    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top: Today's shift info
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: entry.shiftType.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(entry.shiftType.color)

                    Text("오늘 \(entry.shiftLabel)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                if !entry.timeString.isEmpty {
                    Text(entry.timeString)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(white: 0.6))
                }
            }

            // D-day
            if entry.daysUntilOff > 0 {
                HStack(spacing: 4) {
                    Text("다음 휴무")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))
                    Text("D-\(entry.daysUntilOff)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShiftType.off.color)
                }
            }

            Spacer()

            // Week strip
            HStack(spacing: 4) {
                ForEach(Array(entry.weekShifts.prefix(7).enumerated()), id: \.offset) { index, shift in
                    VStack(spacing: 3) {
                        Text(weekdayString(for: shift.date))
                            .font(.system(size: 9))
                            .foregroundColor(index == 0 ? .white : Color(white: 0.5))

                        Text(dayString(for: shift.date))
                            .font(.system(size: 10, weight: index == 0 ? .bold : .medium))
                            .foregroundColor(index == 0 ? .white : Color(white: 0.7))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(shift.type.color.opacity(index == 0 ? 1.0 : 0.7))
                            .frame(height: 4)

                        Text(shift.type.shortLabel)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(shift.type.color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        index == 0
                            ? RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.08))
                            : nil
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Color(red: 0.1, green: 0.08, blue: 0.07)
        }
    }

    private func weekdayString(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return weekdayLabels[weekday - 1]
    }

    private func dayString(for date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
}
