import SwiftUI

@main
struct LapTimerApp: App {
    @StateObject private var store = TrackStore()
    @StateObject private var location = LocationService()
    @StateObject private var recordsStore = RecordsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(location)
                .environmentObject(recordsStore)
                .preferredColorScheme(.dark)
                .tint(Color(hex: 0xFF2E3A))
        }
    }
}
