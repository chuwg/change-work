import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var todaySteps: Int = 0
    @Published var latestHeartRate: Double = 0
    @Published var isAuthorized: Bool = false

    // Sleep data
    @Published var lastSleepHours: Double = 0
    @Published var lastSleepBedTime: Date?
    @Published var lastSleepWakeTime: Date?
    @Published var sleepQuality: Int = 0  // 1-5 from sleep stages
    @Published var deepSleepMin: Double = 0
    @Published var remSleepMin: Double = 0
    @Published var lightSleepMin: Double = 0

    private let readTypes: Set<HKSampleType> = {
        var types: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        ]
        // Sleep types
        if let asleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(asleep)
        }
        return types
    }()

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchAll()
                }
            }
        }
    }

    func fetchAll() {
        fetchTodaySteps()
        fetchLatestHeartRate()
        fetchLastNightSleep()
    }

    func fetchTodaySteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay, end: Date(), options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            DispatchQueue.main.async {
                self?.todaySteps = Int(steps)
            }
        }

        healthStore.execute(query)
    }

    func fetchLatestHeartRate() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate, ascending: false
        )

        let query = HKSampleQuery(
            sampleType: hrType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(
                for: HKUnit.count().unitDivided(by: .minute())
            )
            DispatchQueue.main.async {
                self?.latestHeartRate = bpm
            }
        }

        healthStore.execute(query)
    }

    /// Fetch last night's sleep data from HealthKit (Apple Watch auto-records)
    func fetchLastNightSleep() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let calendar = Calendar.current
        let now = Date()
        // Look back 24 hours for the most recent sleep session
        let startLookback = calendar.date(byAdding: .hour, value: -36, to: now)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startLookback, end: now, options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate, ascending: false
        )

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKCategorySample], !samples.isEmpty else { return }

            // Separate by sleep stage
            var deep: Double = 0
            var rem: Double = 0
            let light: Double = 0
            var core: Double = 0  // Apple Watch "core sleep"
            var asleep: Double = 0
            var inBed: Double = 0

            var earliestBed: Date?
            var latestWake: Date?

            for sample in samples {
                let minutes = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                // Skip very short segments (< 5 min)
                guard minutes >= 5 else { continue }

                let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)

                switch value {
                case .asleepDeep:
                    deep += minutes
                    self?.updateSleepWindow(sample: sample, earliest: &earliestBed, latest: &latestWake)
                case .asleepREM:
                    rem += minutes
                    self?.updateSleepWindow(sample: sample, earliest: &earliestBed, latest: &latestWake)
                case .asleepCore:
                    core += minutes
                    self?.updateSleepWindow(sample: sample, earliest: &earliestBed, latest: &latestWake)
                case .asleepUnspecified:
                    asleep += minutes
                    self?.updateSleepWindow(sample: sample, earliest: &earliestBed, latest: &latestWake)
                case .inBed:
                    inBed += minutes
                    self?.updateSleepWindow(sample: sample, earliest: &earliestBed, latest: &latestWake)
                default:
                    break
                }
            }

            // Total actual sleep (excluding awake/inBed-only)
            let totalSleepMin = deep + rem + core + asleep
            // If no stage data, fall back to inBed time
            let effectiveSleepMin = totalSleepMin > 0 ? totalSleepMin : inBed
            let sleepHours = effectiveSleepMin / 60.0

            // Calculate quality from stages (1-5)
            let quality: Int
            if totalSleepMin > 30 {
                // Weighted: deep sleep and REM are most restorative
                let totalStaged = deep + rem + core
                let deepRatio = totalStaged > 0 ? (deep + rem) / totalStaged : 0.3
                let hoursScore = min(sleepHours / 8.0, 1.0) * 3  // max 3 points
                let stageScore = deepRatio * 2  // max 2 points
                quality = max(1, min(5, Int((hoursScore + stageScore).rounded())))
            } else {
                // No stage data - estimate from hours only
                if sleepHours >= 7.5 { quality = 4 }
                else if sleepHours >= 6.5 { quality = 3 }
                else if sleepHours >= 5.0 { quality = 2 }
                else { quality = 1 }
            }

            DispatchQueue.main.async {
                self?.lastSleepHours = sleepHours
                self?.lastSleepBedTime = earliestBed
                self?.lastSleepWakeTime = latestWake
                self?.sleepQuality = quality
                self?.deepSleepMin = deep
                self?.remSleepMin = rem
                self?.lightSleepMin = core + light

                // Also write to shared UserDefaults for widget
                self?.writeSleepToShared(hours: sleepHours, quality: quality)
            }
        }

        healthStore.execute(query)
    }

    private func updateSleepWindow(sample: HKCategorySample, earliest: inout Date?, latest: inout Date?) {
        if earliest == nil || sample.startDate < earliest! {
            earliest = sample.startDate
        }
        if latest == nil || sample.endDate > latest! {
            latest = sample.endDate
        }
    }

    private func writeSleepToShared(hours: Double, quality: Int) {
        guard let defaults = UserDefaults(suiteName: "group.com.change.app.change") else { return }
        defaults.set(hours, forKey: "widget_sleep_hours")
        defaults.set(quality, forKey: "widget_sleep_quality")
    }

    /// Compute condition score (0-100) matching the Flutter app logic
    var conditionScore: Int {
        var score: Double = 0
        var totalWeight: Double = 0

        // Sleep factor (40%)
        if lastSleepHours > 0 {
            var sleepScore: Double
            if lastSleepHours >= 7 && lastSleepHours <= 9 {
                sleepScore = 90
            } else if lastSleepHours >= 6 {
                sleepScore = 70
            } else if lastSleepHours >= 5 {
                sleepScore = 50
            } else {
                sleepScore = 30
            }
            sleepScore += Double(sleepQuality - 3) * 5
            sleepScore = max(0, min(100, sleepScore))
            score += sleepScore * 0.4
            totalWeight += 0.4
        }

        // Energy factor (35%) - read from shared defaults
        let energyLevel = UserDefaults(suiteName: "group.com.change.app.change")?
            .integer(forKey: "widget_energy_latest") ?? 0
        if energyLevel > 0 {
            let energyScore = (Double(energyLevel) / 5.0) * 100
            score += energyScore * 0.35
            totalWeight += 0.35
        }

        // Activity factor (25%)
        if todaySteps > 0 {
            let activityScore: Double
            if todaySteps >= 8000 { activityScore = 90 }
            else if todaySteps >= 5000 { activityScore = 70 }
            else if todaySteps >= 3000 { activityScore = 50 }
            else { activityScore = 30 }
            score += activityScore * 0.25
            totalWeight += 0.25
        }

        if totalWeight == 0 { return 50 }
        return max(0, min(100, Int((score / totalWeight).rounded())))
    }

    func refresh() {
        fetchAll()
    }
}
