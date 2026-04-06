import SwiftUI

struct HealthSummaryView: View {
    @StateObject private var healthKit = HealthKitManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Condition Score
                conditionScoreCard

                // Sleep Analysis
                sleepCard

                // Activity
                activityCard

                // Heart Rate
                heartRateCard
            }
            .padding(.horizontal, 4)
        }
        .background(Color(red: 0.1, green: 0.08, blue: 0.07))
        .onAppear {
            healthKit.requestAuthorization()
        }
    }

    // MARK: - Condition Score
    private var conditionScoreCard: some View {
        let score = healthKit.conditionScore
        let color = scoreColor(score)
        let label = scoreLabel(score)

        return VStack(spacing: 6) {
            Text("오늘의 컨디션")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(white: 0.5))

            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color)
                    Text(label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(color)
                }
            }

            // Factor indicators
            HStack(spacing: 12) {
                factorDot(
                    icon: "moon.zzz.fill",
                    active: healthKit.lastSleepHours > 0,
                    color: Color(red: 0.45, green: 0.39, blue: 0.94)
                )
                factorDot(
                    icon: "bolt.fill",
                    active: (UserDefaults(suiteName: "group.com.change.app.change")?
                        .integer(forKey: "widget_energy_latest") ?? 0) > 0,
                    color: Color(red: 1.0, green: 0.6, blue: 0.2)
                )
                factorDot(
                    icon: "figure.walk",
                    active: healthKit.todaySteps > 0,
                    color: Color(red: 0.30, green: 0.69, blue: 0.31)
                )
            }
        }
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func factorDot(icon: String, active: Bool, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 12))
            .foregroundColor(active ? color : Color(white: 0.3))
    }

    // MARK: - Sleep Card
    private var sleepCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.45, green: 0.39, blue: 0.94))
                .frame(width: 28, height: 28)
                .background(Color(red: 0.45, green: 0.39, blue: 0.94).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text("수면")
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.5))

                if healthKit.lastSleepHours > 0 {
                    Text(String(format: "%.1f시간", healthKit.lastSleepHours))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Text("품질 \(qualityStars(healthKit.sleepQuality))")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.45))

                        if healthKit.deepSleepMin > 0 || healthKit.remSleepMin > 0 {
                            Text("깊은\(Int(healthKit.deepSleepMin))분")
                                .font(.system(size: 9))
                                .foregroundColor(Color(red: 0.45, green: 0.39, blue: 0.94).opacity(0.7))
                        }
                    }

                    if let bed = healthKit.lastSleepBedTime, let wake = healthKit.lastSleepWakeTime {
                        Text("\(formatTime(bed)) - \(formatTime(wake))")
                            .font(.system(size: 9))
                            .foregroundColor(Color(white: 0.4))
                    }
                } else {
                    Text("--")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Apple Watch 착용 시 자동 기록")
                        .font(.system(size: 9))
                        .foregroundColor(Color(white: 0.4))
                }
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Activity Card
    private var activityCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "figure.walk")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.30, green: 0.69, blue: 0.31))
                .frame(width: 28, height: 28)
                .background(Color(red: 0.30, green: 0.69, blue: 0.31).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text("걸음 수")
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.5))

                Text(healthKit.todaySteps > 0 ? formatSteps(healthKit.todaySteps) : "--")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                if healthKit.todaySteps > 0 {
                    let goal = 8000
                    let progress = min(Double(healthKit.todaySteps) / Double(goal), 1.0)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(white: 0.2))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(red: 0.30, green: 0.69, blue: 0.31))
                                .frame(width: geo.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Heart Rate Card
    private var heartRateCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.90, green: 0.44, blue: 0.44))
                .frame(width: 28, height: 28)
                .background(Color(red: 0.90, green: 0.44, blue: 0.44).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text("심박수")
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.5))

                Text(healthKit.latestHeartRate > 0
                     ? "\(Int(healthKit.latestHeartRate)) BPM"
                     : "--")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers
    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return Color(red: 0.30, green: 0.69, blue: 0.31) }
        if score >= 60 { return Color(red: 0.91, green: 0.73, blue: 0.29) }
        return Color(red: 0.88, green: 0.48, blue: 0.48)
    }

    private func scoreLabel(_ score: Int) -> String {
        if score >= 80 { return "좋음" }
        if score >= 60 { return "보통" }
        return "주의"
    }

    private func qualityStars(_ quality: Int) -> String {
        String(repeating: "\u{2605}", count: quality) +
        String(repeating: "\u{2606}", count: max(0, 5 - quality))
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
