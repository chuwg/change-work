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
        if !ScreenshotMode.isActive {
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { _, _ in }
        }
        scheduleShiftNotifications()
    }

    func applicationDidBecomeActive() {
        scheduleShiftNotifications()
    }

    /// Schedules only the shift *end* notification.
    ///
    /// The start reminder deliberately lives on the phone: it honours the
    /// user's configured commute time ("지금 출발하세요!") and iOS forwards it
    /// to the watch when the phone is not in use. The watch used to schedule
    /// its own hardcoded 10-minute warning on top of that, which meant two
    /// different alerts for one shift.
    private func scheduleShiftNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // Resolved by date, so a day rollover cannot leave yesterday's shift here.
        let start = WidgetDataReader.readTodayStart()
        let end = WidgetDataReader.readTodayEnd()
        let label = WidgetDataReader.readTodayLabel()
        let type = WidgetDataReader.readTodayType()

        guard type != .off && type != .none else { return }

        guard var endDate = parseTimeToday(end) else { return }
        // A night shift ends the next morning.
        if let startDate = parseTimeToday(start), endDate <= startDate {
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
        }
        guard endDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "근무 종료"
        content.body = "\(label) 근무가 종료되었습니다. 수고하셨습니다!"
        content.sound = .default

        // Full date components: hour/minute alone is not bound to a day, so an
        // overnight shift's end could match the wrong occurrence.
        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: endDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: comps, repeats: false
        )
        center.add(UNNotificationRequest(
            identifier: "shift_end", content: content, trigger: trigger
        ))
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
