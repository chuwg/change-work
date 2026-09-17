import EventKit
import Flutter
import Foundation

/// Mirrors the shift schedule into a dedicated "Change 근무" calendar.
///
/// Everything goes into a calendar this app owns, never the user's own ones:
/// a sync can then simply clear its window and rewrite it, with no risk of
/// touching an event the user made, and turning the feature off is just
/// deleting that calendar. Living in iCloud (when available) also means the
/// user can share it with family from the Calendar app.
final class CalendarSyncBridge: NSObject {
    static let shared = CalendarSyncBridge()

    private static let channelName = "com.change.app/calendar"
    private static let calendarIdKey = "change_calendar_identifier"
    private static let calendarTitle = "Change 근무"

    private let store = EKEventStore()

    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: Self.channelName, binaryMessenger: messenger)

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "authorizationStatus":
                result(self.authorizationStatus())

            case "requestAccess":
                self.requestAccess { granted in
                    DispatchQueue.main.async { result(granted) }
                }

            case "sync":
                guard let args = call.arguments as? [String: Any],
                      let from = args["from"] as? String,
                      let to = args["to"] as? String,
                      let events = args["events"] as? [[String: Any]]
                else {
                    result(FlutterError(code: "bad_args", message: "expected from/to/events", details: nil))
                    return
                }
                DispatchQueue.global(qos: .utility).async {
                    let outcome = self.sync(from: from, to: to, events: events)
                    DispatchQueue.main.async { result(outcome) }
                }

            case "removeCalendar":
                result(self.removeCalendar())

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    // MARK: - Access

    private func authorizationStatus() -> String {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: return "notDetermined"
        case .denied, .restricted: return "denied"
        case .writeOnly: return "writeOnly"
        default: return "authorized"  // .authorized / .fullAccess
        }
    }

    private func requestAccess(_ completion: @escaping (Bool) -> Void) {
        // Full access, not write-only: the sync has to find its own previous
        // events to replace them.
        if #available(iOS 17.0, *) {
            store.requestFullAccessToEvents { granted, _ in completion(granted) }
        } else {
            store.requestAccess(to: .event) { granted, _ in completion(granted) }
        }
    }

    // MARK: - Calendar

    private func ownCalendar(create: Bool) -> EKCalendar? {
        let defaults = UserDefaults.standard
        if let id = defaults.string(forKey: Self.calendarIdKey),
           let calendar = store.calendar(withIdentifier: id) {
            return calendar
        }
        guard create else { return nil }

        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = Self.calendarTitle
        calendar.cgColor = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1).cgColor
        guard let source = preferredSource() else { return nil }
        calendar.source = source
        do {
            try store.saveCalendar(calendar, commit: true)
        } catch {
            return nil
        }
        defaults.set(calendar.calendarIdentifier, forKey: Self.calendarIdKey)
        return calendar
    }

    /// iCloud if the user has it (so the calendar syncs and can be shared),
    /// otherwise wherever their default calendar lives, otherwise on-device.
    private func preferredSource() -> EKSource? {
        let sources = store.sources
        if let iCloud = sources.first(where: { $0.sourceType == .calDAV && $0.title == "iCloud" }) {
            return iCloud
        }
        if let source = store.defaultCalendarForNewEvents?.source {
            return source
        }
        return sources.first { $0.sourceType == .local }
    }

    private func removeCalendar() -> Bool {
        guard let calendar = ownCalendar(create: false) else { return true }
        do {
            try store.removeCalendar(calendar, commit: true)
            UserDefaults.standard.removeObject(forKey: Self.calendarIdKey)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Sync

    /// Replace every event in [from, to] with [events]. Returns the number
    /// written, or a FlutterError.
    private func sync(from: String, to: String, events: [[String: Any]]) -> Any {
        guard authorizationStatus() == "authorized" else {
            return FlutterError(code: "no_access", message: "calendar access not granted", details: nil)
        }
        guard let calendar = ownCalendar(create: true) else {
            return FlutterError(code: "no_calendar", message: "could not create calendar", details: nil)
        }
        guard let rangeStart = Self.day(from),
              let rangeEndDay = Self.day(to),
              let rangeEnd = Calendar.current.date(byAdding: .day, value: 2, to: rangeEndDay)
        else {
            return FlutterError(code: "bad_args", message: "bad range", details: nil)
        }

        do {
            // +2 days so a night shift starting on the last day, which ends the
            // morning after, is still found and replaced.
            let predicate = store.predicateForEvents(
                withStart: rangeStart, end: rangeEnd, calendars: [calendar])
            for event in store.events(matching: predicate) {
                try store.remove(event, span: .thisEvent, commit: false)
            }

            var written = 0
            for item in events {
                guard let event = makeEvent(item, calendar: calendar) else { continue }
                try store.save(event, span: .thisEvent, commit: false)
                written += 1
            }
            try store.commit()
            return written
        } catch {
            store.reset()
            return FlutterError(code: "save_failed", message: error.localizedDescription, details: nil)
        }
    }

    private func makeEvent(_ item: [String: Any], calendar: EKCalendar) -> EKEvent? {
        guard let dateStr = item["date"] as? String,
              let day = Self.day(dateStr),
              let title = item["title"] as? String
        else { return nil }

        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = title
        event.notes = item["note"] as? String

        let cal = Calendar.current
        if let start = Self.time(item["start"] as? String, on: day),
           var end = Self.time(item["end"] as? String, on: day) {
            if end <= start {
                end = cal.date(byAdding: .day, value: 1, to: end) ?? end
            }
            event.startDate = start
            event.endDate = end
        } else {
            event.isAllDay = true
            event.startDate = day
            event.endDate = day
        }
        return event
    }

    private static func day(_ yyyyMMdd: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: yyyyMMdd)
    }

    private static func time(_ hhmm: String?, on day: Date) -> Date? {
        guard let parts = hhmm?.split(separator: ":"), parts.count >= 2,
              let h = Int(parts[0]), let m = Int(parts[1])
        else { return nil }
        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: day)
    }
}
