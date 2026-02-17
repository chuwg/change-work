import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayShiftView()
            WeekScheduleView()
            HealthSummaryView()
            ShiftTimerView()
            EnergyRecordView()
        }
        .tabViewStyle(.verticalPage)
    }
}
