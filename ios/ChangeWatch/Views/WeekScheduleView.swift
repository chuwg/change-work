import SwiftUI

struct WeekScheduleView: View {
    private let weekShifts = WidgetDataReader.readWeekShifts()
    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(spacing: 8) {
            Text("이번 주 근무")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 2) {
                ForEach(Array(weekShifts.prefix(7).enumerated()), id: \.offset) { index, shift in
                    VStack(spacing: 3) {
                        Text(weekdayString(for: shift.date))
                            .font(.system(size: 9))
                            .foregroundColor(index == 0 ? .white : Color(white: 0.5))

                        Text(dayString(for: shift.date))
                            .font(.system(size: 11, weight: index == 0 ? .bold : .medium))
                            .foregroundColor(index == 0 ? .white : Color(white: 0.65))

                        Circle()
                            .fill(shift.type.color.opacity(index == 0 ? 1.0 : 0.6))
                            .frame(width: 6, height: 6)

                        Text(shift.type.shortLabel)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(shift.type.color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        index == 0
                            ? RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                            : nil
                    )
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.1, green: 0.08, blue: 0.07))
    }

    private func weekdayString(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return weekdayLabels[weekday - 1]
    }

    private func dayString(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }
}
