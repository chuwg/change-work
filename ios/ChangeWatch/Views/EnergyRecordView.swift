import SwiftUI
import WatchKit

struct EnergyRecordView: View {
    @State private var recorded = false
    @State private var recordedLevel: Int = 0

    private let levels: [(level: Int, label: String, icon: String, color: Color)] = [
        (5, "최고", "battery.100.bolt", Color(red: 0.49, green: 0.72, blue: 0.54)),
        (4, "좋음", "battery.75", Color(red: 0.62, green: 0.77, blue: 0.63)),
        (3, "보통", "battery.50", Color(red: 0.91, green: 0.73, blue: 0.29)),
        (2, "피곤", "battery.25", Color(red: 0.88, green: 0.48, blue: 0.48)),
        (1, "탈진", "battery.0", Color(red: 0.83, green: 0.40, blue: 0.35)),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                if recorded {
                    // Confirmation
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.49, green: 0.72, blue: 0.54))

                        Text("기록 완료!")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        Text(energyLabel(recordedLevel))
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.6))

                        Button("다시 기록") {
                            recorded = false
                        }
                        .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("에너지 기록")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(levels, id: \.level) { item in
                        Button {
                            recordEnergy(level: item.level)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(item.color)
                                    .frame(width: 28)

                                Text(item.label)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(item.level)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(item.color)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(item.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color(red: 0.1, green: 0.08, blue: 0.07))
    }

    private func recordEnergy(level: Int) {
        WatchDataWriter.writeEnergyRecord(level: level)
        WKInterfaceDevice.current().play(.success)
        recordedLevel = level
        withAnimation(.easeInOut(duration: 0.3)) {
            recorded = true
        }
    }

    private func energyLabel(_ level: Int) -> String {
        levels.first(where: { $0.level == level })?.label ?? ""
    }
}
