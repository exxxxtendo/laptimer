import SwiftUI

struct RootView: View {
    @EnvironmentObject var location: LocationService
    var body: some View {
        NavigationView { TracksListView() }
            .navigationViewStyle(.stack)
            .onAppear { location.requestPermission() }
    }
}
