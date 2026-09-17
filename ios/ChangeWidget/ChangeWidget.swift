import SwiftUI
import WidgetKit

struct ChangeWidget: Widget {
    let kind: String = "ChangeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChangeWidgetProvider()) { entry in
            ChangeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("교대근무")
        .description("오늘 근무, 이번 주 스케줄, 다음 출근·퇴근까지 남은 시간을 확인하세요.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryRectangular, .accessoryInline, .accessoryCircular,
        ])
    }
}

struct ChangeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ChangeWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            ShiftWidgetView(entry: entry)
        case .systemMedium:
            WeekWidgetView(entry: entry)
        case .accessoryRectangular, .accessoryInline, .accessoryCircular:
            LockScreenShiftView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        default:
            ShiftWidgetView(entry: entry)
        }
    }
}
