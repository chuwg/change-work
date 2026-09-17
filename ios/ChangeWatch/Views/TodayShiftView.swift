import SwiftUI

struct TodayShiftView: View {
    @StateObject private var store = WatchScheduleStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch store.availability {
            case .available:
                shiftContent
            case .noShiftToday:
                emptyState(
                    icon: "calendar.badge.plus",
                    title: "오늘 근무가 없어요",
                    detail: "아래로 넘겨 이번 주를 확인하거나 근무를 등록하세요"
                )
                nextShiftLine
            case .neverSynced:
                emptyState(
                    icon: "iphone.gen3",
                    title: "아이폰과 동기화 전이에요",
                    detail: "아이폰에서 Change 앱을 한 번 열어주세요"
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.1, green: 0.08, blue: 0.07))
        // The shared container is written by the phone, so re-read whenever
        // this screen comes back into view.
        .onAppear { store.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refresh() }
        }
    }

    @ViewBuilder
    private var shiftContent: some View {
        let shift = store.today
        let type = shift?.type ?? ShiftType.none

        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(type.color)

            Text(type == .off ? "휴무" : "\(type.label) 근무")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }

        if let shift, !shift.start.isEmpty, !shift.end.isEmpty {
            Text("\(shift.start) - \(shift.end)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(white: 0.6))
        }

        Spacer()

        nextShiftLine

        if type == .off {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(ShiftType.off.color)
                Text("오늘 휴무")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ShiftType.off.color)
            }
        } else if store.daysUntilOff > 0 {
            HStack(spacing: 6) {
                Text("휴무까지")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.5))
                Text("D-\(store.daysUntilOff)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ShiftType.off.color)
            }
        }
    }

    /// "출근까지 3시간 12분" — the live countdown to the next boundary, which
    /// on a day off already points at the next working day.
    @ViewBuilder
    private var nextShiftLine: some View {
        // Re-evaluated each minute so it flips to 퇴근 when the shift starts
        // instead of counting up past the start time.
        TimelineView(.periodic(from: Date(), by: 60)) { timeline in
            if let event = WidgetDataReader.nextShiftEvent(in: store.week, at: timeline.date) {
            HStack(spacing: 4) {
                Text(event.inProgress ? "퇴근까지" : "\(event.shift.type.label) 출근까지")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.5))
                Text(event.target, style: .relative)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(event.shift.type.color)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            }
        }
    }

    private func emptyState(
        icon: String,
        title: String,
        detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(white: 0.45))
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text(detail)
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
