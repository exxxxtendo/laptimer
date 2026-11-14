import SwiftUI

@main
struct LapTimerApp: App {
    @StateObject private var store = TrackStore()
    @StateObject private var location = LocationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(location)
                .preferredColorScheme(.dark)
        }
    }
}
