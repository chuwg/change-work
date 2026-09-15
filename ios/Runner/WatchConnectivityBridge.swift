import Flutter
import Foundation
import WatchConnectivity

/// Carries data between the phone app and the watch app.
///
/// App Groups only share a container between an app and its extensions *on the
/// same device*. The watch is a separate device, so everything this app used to
/// push through `UserDefaults(suiteName:)` never actually reached the watch —
/// WatchConnectivity is the only channel that crosses.
///
/// Phone → watch uses `updateApplicationContext`: the watch may well be asleep,
/// and this delivers the latest state whenever it next wakes, which is exactly
/// the semantics a schedule snapshot wants (newest wins, no queue to drain).
///
/// Watch → phone uses `transferUserInfo`: shift edits and energy taps are
/// discrete events, so they queue up and arrive in order even if the phone is
/// in the background.
final class WatchConnectivityBridge: NSObject {
    static let shared = WatchConnectivityBridge()

    private static let channelName = "com.change.app/watch"

    private var channel: FlutterMethodChannel?

    /// Payloads that arrived before Flutter was ready to receive them.
    private var pendingInbound: [[String: Any]] = []

    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: Self.channelName, binaryMessenger: messenger)
        self.channel = channel

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            switch call.method {
            case "isSupported":
                result(WCSession.isSupported())

            case "isReachable":
                result(WCSession.isSupported() && WCSession.default.isPaired
                       && WCSession.default.isWatchAppInstalled)

            case "sendContext":
                guard let context = call.arguments as? [String: Any] else {
                    result(FlutterError(code: "bad_args",
                                        message: "expected a map", details: nil))
                    return
                }
                result(self.sendContext(context))

            case "drainInbound":
                // Flutter pulls anything that arrived before it was listening.
                let queued = self.pendingInbound
                self.pendingInbound = []
                result(queued)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        activate()

        // Anything already queued can go up as soon as Flutter attaches.
        flushInbound()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Replace the watch's copy of the schedule. Returns false when there is
    /// no watch to send to, so the caller can stay quiet about it.
    @discardableResult
    private func sendContext(_ context: [String: Any]) -> Bool {
        guard WCSession.isSupported() else { return false }
        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled else { return false }

        do {
            try session.updateApplicationContext(context)
            return true
        } catch {
            NSLog("[WatchBridge] updateApplicationContext failed: \(error)")
            return false
        }
    }

    private func deliverInbound(_ payload: [String: Any]) {
        pendingInbound.append(payload)
        flushInbound()
    }

    private func flushInbound() {
        guard let channel, !pendingInbound.isEmpty else { return }
        let queued = pendingInbound
        pendingInbound = []
        DispatchQueue.main.async {
            channel.invokeMethod("onWatchPayload", arguments: queued)
        }
    }
}

extension WatchConnectivityBridge: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith state: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            NSLog("[WatchBridge] activation failed: \(error)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate so a switched watch keeps working.
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        deliverInbound(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        deliverInbound(message)
    }
}
