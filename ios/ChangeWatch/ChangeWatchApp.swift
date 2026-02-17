import SwiftUI
import UserNotifications

@main
struct ChangeWatchApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
        scheduleShiftNotifications()
    }

    func applicationDidBecomeActive() {
        scheduleShiftNotifications()
    }

    private func scheduleShiftNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let start = WidgetDataReader.readTodayStart()
        let end = WidgetDataReader.readTodayEnd()
        let label = WidgetDataReader.readTodayLabel()
        let type = WidgetDataReader.readTodayType()

        guard type != .off && type != .none else { return }

        // Shift start notification (10 min before)
        if let startDate = parseTimeToday(start) {
            let triggerDate = startDate.addingTimeInterval(-10 * 60)
            if triggerDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "근무 시작 알림"
                content.body = "\(label) 근무가 10분 후 시작됩니다 (\(start))"
                content.sound = .default

                let comps = Calendar.current.dateComponents(
                    [.hour, .minute], from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: comps, repeats: false
                )
                center.add(UNNotificationRequest(
                    identifier: "shift_start", content: content, trigger: trigger
                ))
            }
        }

        // Shift end notification
        if let endDate = parseTimeToday(end) {
            var adjustedEnd = endDate
            if let startDate = parseTimeToday(start), endDate <= startDate {
                adjustedEnd = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
            }
            if adjustedEnd > Date() {
                let content = UNMutableNotificationContent()
                content.title = "근무 종료"
                content.body = "\(label) 근무가 종료되었습니다. 수고하셨습니다!"
                content.sound = .default

                let comps = Calendar.current.dateComponents(
                    [.hour, .minute], from: adjustedEnd
                )
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: comps, repeats: false
                )
                center.add(UNNotificationRequest(
                    identifier: "shift_end", content: content, trigger: trigger
                ))
            }
        }
    }

    private func parseTimeToday(_ timeStr: String) -> Date? {
        guard timeStr.count >= 5 else { return nil }
        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1])
        else { return nil }

        var comps = Calendar.current.dateComponents(
            [.year, .month, .day], from: Date()
        )
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps)
    }
}
