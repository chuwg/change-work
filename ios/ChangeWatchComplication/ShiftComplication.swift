import SwiftUI
import WidgetKit

struct ShiftComplication: Widget {
    let kind: String = "ShiftComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShiftComplicationProvider()) { entry in
            ShiftComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("오늘 근무")
        .description("오늘의 근무 일정을 확인하세요")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline,
        ])
    }
}
