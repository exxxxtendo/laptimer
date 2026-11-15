import SwiftUI

@main
struct LapTimerApp: App {
    @StateObject private var store = TrackStore()
    @StateObject private var location = LocationService()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var recordsStore = RecordsStore() // НОВОЕ

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(location)
                .environmentObject(themeManager)
                .environmentObject(recordsStore) // НОВОЕ
                .preferredColorScheme(.dark)
        }
    }
}
