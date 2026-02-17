import SwiftUI
import WidgetKit

struct ShiftWidgetView: View {
    let entry: ChangeWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Shift icon + label
            HStack(spacing: 6) {
                Image(systemName: entry.shiftType.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(entry.shiftType.color)

                Text(entry.shiftLabel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            // Time
            if !entry.timeString.isEmpty {
                Text(entry.timeString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(white: 0.7))
            }

            Spacer()

            // Days until off
            if entry.daysUntilOff > 0 {
                HStack(spacing: 4) {
                    Text("휴무까지")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))
                    Text("D-\(entry.daysUntilOff)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ShiftType.off.color)
                }
            } else if entry.shiftType == .off {
                Text("오늘 휴무")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ShiftType.off.color)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Color(red: 0.1, green: 0.08, blue: 0.07)
        }
    }
}
