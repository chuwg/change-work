import SwiftUI
import WidgetKit

struct ShiftComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ShiftComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryCorner:
            cornerView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // MARK: - Circular
    private var circularView: some View {
        ZStack {
            if entry.daysUntilOff > 0 {
                // Show progress ring until next off day (max 7 days)
                let progress = max(0, 1.0 - Double(entry.daysUntilOff) / 7.0)
                Gauge(value: progress) {
                    EmptyView()
                } currentValueLabel: {
                    Image(systemName: entry.shiftType.icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(entry.shiftType.color)
            } else {
                VStack(spacing: 1) {
                    Image(systemName: entry.shiftType.icon)
                        .font(.system(size: 18, weight: .semibold))
                    Text(entry.shiftType.shortLabel)
                        .font(.system(size: 10, weight: .bold))
                }
            }
        }
    }

    // MARK: - Rectangular
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.shiftType.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(entry.shiftLabel)
                    .font(.system(size: 14, weight: .bold))
                if !entry.timeString.isEmpty {
                    Spacer()
                    Text(entry.timeString)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            if entry.shiftType == .off {
                Text("오늘 휴무")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            } else if entry.daysUntilOff > 0 {
                Text("다음 휴무 D-\(entry.daysUntilOff)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Corner
    private var cornerView: some View {
        Image(systemName: entry.shiftType.icon)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(entry.shiftType.color)
            .widgetLabel {
                if entry.daysUntilOff > 0 {
                    Text("D-\(entry.daysUntilOff)")
                } else {
                    Text(entry.shiftLabel)
                }
            }
    }

    // MARK: - Inline
    private var inlineView: some View {
        if entry.shiftType == .off {
            Text("휴무")
        } else if !entry.timeString.isEmpty {
            Text("\(entry.shiftLabel) \(entry.timeString)")
        } else {
            Text(entry.shiftLabel)
        }
    }
}
