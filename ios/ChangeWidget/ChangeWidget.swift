import SwiftUI
import WidgetKit

struct ChangeWidget: Widget {
    let kind: String = "ChangeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChangeWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                ChangeWidgetEntryView(entry: entry)
            } else {
                ChangeWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("교대근무")
        .description("오늘의 근무 일정과 이번 주 스케줄을 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
        default:
            ShiftWidgetView(entry: entry)
        }
    }
}
