import SwiftUI

/// Ring countdown to the next shift boundary: time to leave before a shift,
/// time left during one.
///
/// Driven by the store's dated week rather than today's flat keys, so a night
/// shift that started yesterday is still counted down after midnight, and a
/// day off points at the next working day instead of a dead end.
struct ShiftTimerView: View {
    @StateObject private var store = WatchScheduleStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { timeline in
            let now = timeline.date
            Group {
                if let event = WidgetDataReader.nextShiftEvent(in: store.week, at: now) {
                    timerView(event: event, now: now)
                } else {
                    noDataView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.1, green: 0.08, blue: 0.07))
        }
        .onAppear { store.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refresh() }
        }
    }

    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 28))
                .foregroundColor(Color(white: 0.4))
            Text("예정된 근무 없음")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(white: 0.6))
            Text("아이폰 앱에서 근무를 등록해주세요")
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.4))
                .multilineTextAlignment(.center)
        }
    }

    private func timerView(event: ShiftEvent, now: Date) -> some View {
        let type = event.shift.type
        let progress: Double = {
            guard event.inProgress else { return 0 }
            let total = event.end.timeIntervalSince(event.start)
            return total > 0 ? min(max(now.timeIntervalSince(event.start) / total, 0), 1) : 0
        }()

        return VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(type.color)
                Text(dayPrefix(event: event, now: now) + type.label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            // Ring drawn directly: a scaled-up `.accessoryCircular` Gauge
            // overflowed its tiny centre label onto the stroke. GeometryReader
            // sizes it to whatever space is left, from 40mm up to Ultra.
            GeometryReader { geo in
                let d = min(geo.size.width, geo.size.height)

                ZStack {
                    Circle()
                        .stroke(type.color.opacity(0.2), lineWidth: Self.ringWidth)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(type.color,
                                style: StrokeStyle(lineWidth: Self.ringWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text(formatInterval(event.target.timeIntervalSince(now)))
                            .font(.system(size: d * 0.20, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text(event.countdownLabel)
                            .font(.system(size: d * 0.075))
                            .foregroundColor(Color(white: 0.55))
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, Self.ringWidth + d * 0.06)
                }
                .frame(width: d, height: d)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: 160)

            Text("\(event.shift.start) → \(event.shift.end)")
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.45))
        }
        .padding(12)
    }

    private static let ringWidth: CGFloat = 12

    private func dayPrefix(event: ShiftEvent, now: Date) -> String {
        if event.inProgress { return "" }
        let calendar = Calendar.current
        if calendar.isDate(event.start, inSameDayAs: now) { return "오늘 " }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(event.start, inSameDayAs: tomorrow) { return "내일 " }
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: event.start)).day ?? 0
        return "\(days)일 후 "
    }

    private func formatInterval(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours >= 24 { return "\(hours / 24)일 \(hours % 24)h" }
        if hours > 0 { return String(format: "%d:%02d", hours, minutes) }
        return "\(minutes)분"
    }
}
