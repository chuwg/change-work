import SwiftUI

struct WeekScheduleView: View {
    @StateObject private var store = WatchScheduleStore.shared
    @Environment(\.scenePhase) private var scenePhase

    /// The day the user tapped, if the shift picker is open.
    @State private var editing: DayShift?

    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(spacing: 6) {
            Text("이번 주 근무")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            if store.week.isEmpty {
                Text("아이폰에서 Change 앱을 한 번 열어주세요")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 3) {
                    ForEach(Array(store.week.prefix(7).enumerated()),
                            id: \.offset) { index, shift in
                        dayBlock(shift, isToday: index == 0)
                    }
                }
                Text("탭해서 근무 변경")
                    .font(.system(size: 9))
                    .foregroundColor(Color(white: 0.4))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.1, green: 0.08, blue: 0.07))
        .onAppear { store.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refresh() }
        }
        .sheet(item: $editing) { day in
            ShiftPickerView(day: day)
        }
    }

    /// A filled block per day rather than a 6pt dot: four shift colours have to
    /// be tellable apart at a glance on a screen this small.
    private func dayBlock(_ shift: DayShift, isToday: Bool) -> some View {
        Button {
            editing = shift
        } label: {
            // All three lines share the on-block colour: the fills are light
            // enough that a grey weekday label disappears into them.
            let onBlock = shift.type == .none
                ? Color(white: 0.6)
                : Color(red: 0.1, green: 0.08, blue: 0.07)

            VStack(spacing: 2) {
                Text(weekdayString(for: shift.date))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(onBlock.opacity(0.75))
                Text(dayString(for: shift.date))
                    .font(.system(size: 12,
                                  weight: isToday ? .bold : .semibold))
                    .foregroundColor(onBlock)
                Text(shift.type.shortLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(onBlock)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(shift.type == .none
                          ? Color.white.opacity(0.08)
                          : shift.type.color.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white, lineWidth: isToday ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
    }

    private func weekdayString(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekdayLabels[weekday - 1]
    }

    private func dayString(for date: Date) -> String {
        "\(Calendar.current.component(.day, from: date))"
    }
}

/// Change one day's shift straight from the watch.
///
/// The watch has no database: the choice is queued into the shared App Group
/// and the phone applies it on its next sync, the same way energy records
/// already travel.
struct ShiftPickerView: View {
    let day: DayShift

    @Environment(\.dismiss) private var dismiss

    private let choices: [ShiftType] = [.day, .evening, .night, .off]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(choices, id: \.rawValue) { type in
                    Button {
                        WatchDataWriter.writeShiftChange(
                            date: day.date, type: type.rawValue)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.system(size: 15))
                                .foregroundColor(type.color)
                            Text(type == .off ? "휴무" : "\(type.label) 근무")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            if type == day.type {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(type.color)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(type.color.opacity(
                                    type == day.type ? 0.3 : 0.15))
                        )
                    }
                    .buttonStyle(.plain)
                }

                Text("아이폰과 동기화되면 반영됩니다")
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.4))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .background(Color(red: 0.1, green: 0.08, blue: 0.07))
    }

    private var title: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: day.date)
    }
}
