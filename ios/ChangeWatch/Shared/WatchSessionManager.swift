import Foundation
import WatchConnectivity

/// The watch half of the phone link.
///
/// The shared App Group container is still used, but only as this watch's own
/// local cache — it is not visible to the phone. Whatever arrives from the
/// phone is written into that cache so every existing reader keeps working,
/// and anything the user does here is sent across rather than left sitting in
/// a queue nobody reads.
final class WatchSessionManager: NSObject {
    static let shared = WatchSessionManager()

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: WatchDataWriter.appGroupId)
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Ask the phone for a fresh snapshot. Harmless when it is unreachable.
    func requestRefresh() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        // Whatever the phone last published is already waiting here.
        applyContext(session.receivedApplicationContext)

        if session.isReachable {
            session.sendMessage(["request": "schedule"], replyHandler: { reply in
                self.applyContext(reply)
            }, errorHandler: { _ in })
        }
    }

    /// Send a shift the user picked on the watch.
    func sendShiftChange(date: Date, type: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"

        transfer([
            "kind": "shift_change",
            "date": formatter.string(from: date),
            "type": type,
            "changed_at": ISO8601DateFormatter().string(from: Date()),
        ])
    }

    /// Send an energy level recorded on the watch.
    func sendEnergyRecord(level: Int) {
        transfer([
            "kind": "energy_record",
            "energy_level": level,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ])
    }

    /// transferUserInfo queues and survives the phone being asleep, which is
    /// what a discrete user action needs — unlike application context, which
    /// only keeps the newest value.
    private func transfer(_ payload: [String: Any]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        session.transferUserInfo(payload)
    }

    /// Write a phone snapshot into the local cache the views read from.
    private func applyContext(_ context: [String: Any]) {
        guard !context.isEmpty, let defaults else { return }

        for (key, value) in context where key.hasPrefix("widget_") {
            defaults.set(value, forKey: key)
        }

        DispatchQueue.main.async {
            WatchScheduleStore.shared.refresh()
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        guard error == nil else { return }
        applyContext(session.receivedApplicationContext)
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        applyContext(applicationContext)
    }
}
