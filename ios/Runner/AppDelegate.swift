import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Watch <-> phone. App Groups do not cross devices, so this is the only
        // channel that actually reaches the watch app.
        //
        // Registered through the plugin registry, NOT window?.rootViewController:
        // this app uses the UIScene lifecycle, so AppDelegate.window is still nil
        // here — the scene creates the window later. The old `if let` failed
        // silently, the bridge never registered, WCSession was never activated
        // on the phone, and the watch sat on "아이폰과 동기화 전이에요" forever.
        WatchConnectivityBridge.shared.activateSession()
        if let registrar = self.registrar(forPlugin: "WatchConnectivityBridge") {
            WatchConnectivityBridge.shared.register(with: registrar.messenger())
        }
        if let registrar = self.registrar(forPlugin: "CalendarSyncBridge") {
            CalendarSyncBridge.shared.register(with: registrar.messenger())
        }

        // HealthKit is synced from Flutter whenever the app is opened
        // (HealthSyncNotifier.autoSync). There used to be a native background
        // delivery pipeline here as well; it never ran — it looked for Flutter's
        // "sync enabled" setting in the App Group, but shared_preferences writes
        // to UserDefaults.standard — and nothing read the values it produced.

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
