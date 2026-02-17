import SwiftUI

struct ShiftTimerView: View {
    private let shiftType = WidgetDataReader.readTodayType()
    private let shiftLabel = WidgetDataReader.readTodayLabel()
    private let startStr = WidgetDataReader.readTodayStart()
    private let endStr = WidgetDataReader.readTodayEnd()

    var body: some View {
        if shiftType == .off {
            offDayView
        } else if shiftType == .none || startStr.isEmpty || endStr.isEmpty {
            noDataView
        } else {
            timerView
        }
    }

    private var offDayView: some View {
        VStack(spacing: 12) {
            Image(systemName: "house.fill")
                .font(.system(size: 32))
                .foregroundColor(ShiftType.off.color)
            Text("오늘 휴무")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("푹 쉬세요!")
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.1, green: 0.08, blue: 0.07))
    }

    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 28))
                .foregroundColor(Color(white: 0.4))
            Text("근무 정보 없음")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(white: 0.6))
            Text("앱에서 근무를 등록해주세요")
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.1, green: 0.08, blue: 0.07))
    }

    private var timerView: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { timeline in
            let now = timeline.date
            let (start, end) = parseTimes(now: now)
            let status = timerStatus(now: now, start: start, end: end)

            VStack(spacing: 8) {
                // Shift info
                HStack(spacing: 6) {
                    Image(systemName: shiftType.icon)
                        .font(.system(size: 14))
                        .foregroundColor(shiftType.color)
                    Text(shiftLabel)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                // Gauge
                Gauge(value: status.progress) {
                    EmptyView()
                } currentValueLabel: {
                    VStack(spacing: 2) {
                        Text(status.timeText)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text(status.label)
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.5))
                    }
                }
                .gaugeStyle(.accessoryCircular)
                .tint(shiftType.color)
                .scaleEffect(2.2)
                .frame(height: 90)

                // Time range
                Text("\(startStr) → \(endStr)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.45))
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.1, green: 0.08, blue: 0.07))
        }
    }

    private struct TimerStatus {
        let progress: Double
        let timeText: String
        let label: String
    }

    private func parseTimes(now: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let todayComps = calendar.dateComponents([.year, .month, .day], from: now)

        func makeDate(_ timeStr: String) -> Date {
            let parts = timeStr.split(separator: ":")
            guard parts.count == 2,
                  let h = Int(parts[0]), let m = Int(parts[1])
            else { return now }
            var comps = todayComps
            comps.hour = h
            comps.minute = m
            return calendar.date(from: comps) ?? now
        }

        var start = makeDate(startStr)
        var end = makeDate(endStr)

        // Handle cross-midnight (night shift)
        if end <= start {
            // If now is before start, shift was yesterday's night shift
            if now < start {
                start = calendar.date(byAdding: .day, value: -1, to: start)!
            } else {
                end = calendar.date(byAdding: .day, value: 1, to: end)!
            }
        }

        return (start, end)
    }

    private func timerStatus(now: Date, start: Date, end: Date) -> TimerStatus {
        let totalSeconds = end.timeIntervalSince(start)

        if now < start {
            // Before shift
            let remaining = start.timeIntervalSince(now)
            return TimerStatus(
                progress: 0,
                timeText: formatInterval(remaining),
                label: "시작까지"
            )
        } else if now >= end {
            // After shift
            return TimerStatus(
                progress: 1.0,
                timeText: "종료",
                label: "수고하셨습니다"
            )
        } else {
            // During shift
            let elapsed = now.timeIntervalSince(start)
            let remaining = end.timeIntervalSince(now)
            let progress = totalSeconds > 0 ? elapsed / totalSeconds : 0
            return TimerStatus(
                progress: min(max(progress, 0), 1),
                timeText: formatInterval(remaining),
                label: "남은 시간"
            )
        }
    }

    private func formatInterval(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        }
        return "\(minutes)분"
    }
}
