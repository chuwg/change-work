import SwiftUI
import WidgetKit

/// Lock screen widgets: what the user most wants at a glance before a shift is
/// how long until they have to leave (or, mid-shift, until they are done).
struct LockScreenShiftView: View {
    @Environment(\.widgetFamily) var family
    let entry: ChangeWidgetEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            inline
        case .accessoryCircular:
            circular
        default:
            rectangular
        }
    }

    @ViewBuilder
    private var rectangular: some View {
        if let event = entry.nextEvent {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Image(systemName: event.shift.type.icon)
                    Text(headline(for: event))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 13))
                Text(event.target, style: .relative)
                    .font(.system(size: 18, weight: .bold))
                    .monospacedDigit()
                Text("\(event.countdownLabel) · \(event.shift.start)-\(event.shift.end)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Label("근무 없음", systemImage: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                Text("앞으로 2주간 등록된 근무가 없어요")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var inline: some View {
        if let event = entry.nextEvent {
            // Inline widgets render a single Text; concatenation keeps the
            // relative part live.
            Text("\(event.shift.type.label) \(event.inProgress ? "퇴근" : "출근") ")
                + Text(event.target, style: .relative)
        } else {
            Text("예정된 근무 없음")
        }
    }

    @ViewBuilder
    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let event = entry.nextEvent {
                VStack(spacing: 0) {
                    Image(systemName: event.shift.type.icon)
                        .font(.system(size: 13, weight: .semibold))
                    Text(event.inProgress ? event.shift.end : event.shift.start)
                        .font(.system(size: 12, weight: .bold))
                        .minimumScaleFactor(0.7)
                }
            } else {
                Image(systemName: entry.shiftType.icon)
                    .font(.system(size: 18, weight: .semibold))
            }
        }
    }

    private func headline(for event: ShiftEvent) -> String {
        let calendar = Calendar.current
        if event.inProgress { return "\(event.shift.type.label) 근무 중" }
        if calendar.isDate(event.start, inSameDayAs: entry.date) {
            return "오늘 \(event.shift.type.label)"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: entry.date),
           calendar.isDate(event.start, inSameDayAs: tomorrow) {
            return "내일 \(event.shift.type.label)"
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d(E)"
        return "\(f.string(from: event.start)) \(event.shift.type.label)"
    }
}

/// "출근까지 3시간 12분" line for the home screen widgets.
struct NextShiftCountdown: View {
    let event: ShiftEvent
    let now: Date
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            Text(event.countdownLabel)
                .font(.system(size: compact ? 10 : 11))
                .foregroundColor(Color(white: 0.5))
            Text(event.target, style: .relative)
                .font(.system(size: compact ? 12 : 13, weight: .bold))
                .foregroundColor(event.shift.type.color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
