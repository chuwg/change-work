import Flutter
import UIKit
import HealthKit
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let healthStore = HKHealthStore()
    private let appGroupId = "group.com.change.app.change"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Register background task for periodic health sync
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.change.app.change.healthSync",
            using: nil
        ) { [weak self] task in
            self?.handleHealthSync(task: task as! BGProcessingTask)
        }

        // Set up HealthKit background delivery if authorized
        setupHealthKitBackgroundDelivery()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        scheduleBackgroundHealthSync()
    }

    // MARK: - HealthKit Background Delivery

    private func setupHealthKitBackgroundDelivery() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        // Check if sync is enabled via shared preferences
        let defaults = UserDefaults(suiteName: appGroupId)
        let syncEnabled = defaults?.bool(forKey: "flutter.health_sync_enabled") ?? false
        guard syncEnabled else { return }

        // Enable background delivery for sleep data
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            healthStore.enableBackgroundDelivery(
                for: sleepType,
                frequency: .hourly
            ) { success, error in
                if let error = error {
                    print("[HealthKit BG] Sleep delivery registration failed: \(error)")
                }
            }
        }

        // Enable background delivery for steps
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            healthStore.enableBackgroundDelivery(
                for: stepType,
                frequency: .hourly
            ) { _, _ in }
        }

        // Enable background delivery for heart rate
        if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            healthStore.enableBackgroundDelivery(
                for: hrType,
                frequency: .hourly
            ) { _, _ in }
        }

        // Set up observer queries
        setupObserverQueries()
    }

    private func setupObserverQueries() {
        // Sleep observer - syncs to shared UserDefaults when new sleep data arrives
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completionHandler, error in
                guard error == nil else {
                    completionHandler()
                    return
                }
                self?.syncLatestSleep {
                    completionHandler()
                }
            }
            healthStore.execute(query)
        }

        // Steps observer
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
                guard error == nil else {
                    completionHandler()
                    return
                }
                self?.syncLatestSteps {
                    completionHandler()
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Sync Methods

    private func syncLatestSleep(completion: @escaping () -> Void) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion()
            return
        }

        let calendar = Calendar.current
        let now = Date()
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
            guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                completion()
                return
            }

            var totalSleepMin: Double = 0
            var deepMin: Double = 0
            var remMin: Double = 0
            var earliestBed: Date?
            var latestWake: Date?

            for sample in samples {
                let minutes = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                guard minutes >= 5 else { continue }

                var isSleepSample = false

                if #available(iOS 16.0, *) {
                    let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                    switch value {
                    case .asleepDeep:
                        deepMin += minutes
                        totalSleepMin += minutes
                        isSleepSample = true
                    case .asleepREM:
                        remMin += minutes
                        totalSleepMin += minutes
                        isSleepSample = true
                    case .asleepCore, .asleepUnspecified:
                        totalSleepMin += minutes
                        isSleepSample = true
                    case .inBed:
                        if totalSleepMin == 0 { totalSleepMin += minutes }
                        isSleepSample = true
                    default:
                        break
                    }
                } else {
                    // iOS 15 and below: only inBed and asleep
                    let value = sample.value
                    if value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                        if totalSleepMin == 0 { totalSleepMin += minutes }
                        isSleepSample = true
                    } else if value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                        totalSleepMin += minutes
                        isSleepSample = true
                    }
                }

                if isSleepSample {
                    if earliestBed == nil || sample.startDate < earliestBed! {
                        earliestBed = sample.startDate
                    }
                    if latestWake == nil || sample.endDate > latestWake! {
                        latestWake = sample.endDate
                    }
                }
            }

            let sleepHours = totalSleepMin / 60.0
            guard sleepHours > 0.5 else {
                completion()
                return
            }

            // Calculate quality
            let quality: Int
            if deepMin + remMin > 30 {
                let totalStaged = deepMin + remMin + (totalSleepMin - deepMin - remMin)
                let deepRatio = totalStaged > 0 ? (deepMin + remMin) / totalStaged : 0.3
                let hoursScore = min(sleepHours / 8.0, 1.0) * 3
                let stageScore = deepRatio * 2
                quality = max(1, min(5, Int((hoursScore + stageScore).rounded())))
            } else {
                if sleepHours >= 7.5 { quality = 4 }
                else if sleepHours >= 6.5 { quality = 3 }
                else if sleepHours >= 5.0 { quality = 2 }
                else { quality = 1 }
            }

            // Write to shared UserDefaults
            let defaults = UserDefaults(suiteName: self?.appGroupId ?? "")
            defaults?.set(sleepHours, forKey: "widget_sleep_hours")
            defaults?.set(quality, forKey: "widget_sleep_quality")

            // Flag that new data is available for Flutter to pick up
            defaults?.set(true, forKey: "health_bg_data_available")
            defaults?.set(ISO8601DateFormatter().string(from: Date()), forKey: "health_bg_last_sync")

            completion()
        }

        healthStore.execute(query)
    }

    private func syncLatestSteps(completion: @escaping () -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion()
            return
        }

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
            let steps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)

            let defaults = UserDefaults(suiteName: self?.appGroupId ?? "")
            defaults?.set(steps, forKey: "widget_today_steps")

            completion()
        }

        healthStore.execute(query)
    }

    // MARK: - Background Task

    private func scheduleBackgroundHealthSync() {
        let request = BGProcessingTaskRequest(
            identifier: "com.change.app.change.healthSync"
        )
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[BG Task] Submit failed: \(error)")
        }
    }

    private func handleHealthSync(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        syncLatestSleep {
            self.syncLatestSteps {
                task.setTaskCompleted(success: true)
                self.scheduleBackgroundHealthSync() // Re-schedule
            }
        }
    }
}
