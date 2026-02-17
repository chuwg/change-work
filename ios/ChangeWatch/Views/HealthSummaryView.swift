import SwiftUI

struct HealthSummaryView: View {
    @StateObject private var healthKit = HealthKitManager.shared

    private let sleepHours = WidgetDataReader.readSleepHours()
    private let sleepQuality = WidgetDataReader.readSleepQuality()
    private let energyLatest = WidgetDataReader.readLatestEnergyLevel()
    private let energyAvg = WidgetDataReader.readAverageEnergy()

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("건강 데이터")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Sleep
                healthCard(
                    icon: "moon.zzz.fill",
                    label: "수면",
                    value: sleepHours > 0
                        ? String(format: "%.1f시간", sleepHours)
                        : "--",
                    detail: sleepQuality > 0
                        ? "품질 \(qualityStars(sleepQuality))"
                        : nil,
                    color: Color(red: 0.45, green: 0.39, blue: 0.94)
                )

                // Energy
                healthCard(
                    icon: "bolt.fill",
                    label: "에너지",
                    value: energyLatest > 0
                        ? energyLabel(energyLatest)
                        : "--",
                    detail: energyAvg > 0
                        ? String(format: "오늘 평균 %.1f", energyAvg)
                        : nil,
                    color: energyColor(energyLatest)
                )

                // Steps
                healthCard(
                    icon: "figure.walk",
                    label: "걸음 수",
                    value: healthKit.todaySteps > 0
                        ? formatSteps(healthKit.todaySteps)
                        : "--",
                    detail: nil,
                    color: Color(red: 0.30, green: 0.69, blue: 0.31)
                )

                // Heart Rate
                healthCard(
                    icon: "heart.fill",
                    label: "심박수",
                    value: healthKit.latestHeartRate > 0
                        ? "\(Int(healthKit.latestHeartRate)) BPM"
                        : "--",
                    detail: nil,
                    color: Color(red: 0.90, green: 0.44, blue: 0.44)
                )
            }
            .padding(.horizontal, 4)
        }
        .background(Color(red: 0.1, green: 0.08, blue: 0.07))
        .onAppear {
            healthKit.requestAuthorization()
        }
    }

    private func healthCard(
        icon: String,
        label: String,
        value: String,
        detail: String?,
        color: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.5))

                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                if let detail = detail {
                    Text(detail)
                        .font(.system(size: 10))
                        .foregroundColor(Color(white: 0.45))
                }
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func qualityStars(_ quality: Int) -> String {
        String(repeating: "★", count: quality) + String(repeating: "☆", count: max(0, 5 - quality))
    }

    private func energyLabel(_ level: Int) -> String {
        switch level {
        case 5: return "최고"
        case 4: return "좋음"
        case 3: return "보통"
        case 2: return "피곤"
        case 1: return "탈진"
        default: return "--"
        }
    }

    private func energyColor(_ level: Int) -> Color {
        switch level {
        case 5: return Color(red: 0.49, green: 0.72, blue: 0.54)
        case 4: return Color(red: 0.62, green: 0.77, blue: 0.63)
        case 3: return Color(red: 0.91, green: 0.73, blue: 0.29)
        case 2: return Color(red: 0.88, green: 0.48, blue: 0.48)
        case 1: return Color(red: 0.83, green: 0.40, blue: 0.35)
        default: return Color(white: 0.4)
        }
    }

    private func formatSteps(_ steps: Int) -> String {
        if steps >= 10000 {
            return String(format: "%.1f만", Double(steps) / 10000.0)
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: steps)) ?? "\(steps)") + "걸음"
    }
}
