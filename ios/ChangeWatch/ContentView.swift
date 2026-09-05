import SwiftUI

/// DEBUG-only hook for capturing App Store screenshots deterministically.
///
/// `SIMCTL_CHILD_CHANGE_INITIAL_TAB=<n> xcrun simctl launch …` opens the app
/// straight to one page and suppresses the permission prompts that would
/// otherwise cover the UI. Compiled out of Release builds entirely.
enum ScreenshotMode {
    /// Driven through the shared defaults rather than a launch environment
    /// variable, because simctl's SIMCTL_CHILD_* vars do not reach a watchOS
    /// app. Set it with:
    ///   xcrun simctl spawn <device> defaults write \
    ///     <container>/Library/Preferences/group.com.change.app.change \
    ///     screenshot_initial_tab -int <n>
    static var initialTab: Int? {
        #if DEBUG
        guard let defaults = UserDefaults(suiteName: WidgetDataReader.appGroupId),
              defaults.object(forKey: "screenshot_initial_tab") != nil
        else { return nil }
        return defaults.integer(forKey: "screenshot_initial_tab")
        #else
        return nil
        #endif
    }

    static var isActive: Bool { initialTab != nil }
}

struct ContentView: View {
    @State private var selection: Int = ScreenshotMode.initialTab ?? 0

    var body: some View {
        TabView(selection: $selection) {
            TodayShiftView().tag(0)
            WeekScheduleView().tag(1)
            HealthSummaryView().tag(2)
            ShiftTimerView().tag(3)
            EnergyRecordView().tag(4)
        }
        .tabViewStyle(.verticalPage)
    }
}
