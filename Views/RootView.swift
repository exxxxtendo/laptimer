import SwiftUI

struct RootView: View {
    @EnvironmentObject var location: LocationService
    @EnvironmentObject var store: TrackStore
    @EnvironmentObject var recordsStore: RecordsStore
    
    @State private var showTracks = false
    @State private var showRecords = false
    @State private var showFreeDrive = false // Открытие пустой карты
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.25, green: 0.0, blue: 0.0), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                HStack(spacing: 30) {
                    MenuButton(title: "TRACKS", icon: "map.fill") { showTracks = true }
                    MenuButton(title: "RECORDS", icon: "trophy.fill") { showRecords = true }
                }
                .padding(.bottom, 50)
            }
            
            // Кнопка по центру открывает пустую карту (Free Drive)
            Button {
                showFreeDrive = true
            } label: {
                Image("BeeLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
            }
        }
        .onAppear { location.requestPermission() }
        .sheet(isPresented: $showTracks) { TracksListView() }
        .sheet(isPresented: $showRecords) { RecordsListView() }
        // Передаем nil как трассу
        .fullScreenCover(isPresented: $showFreeDrive) { SessionView(track: nil) }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 28))
                Text(title).font(.system(size: 16, weight: .heavy, design: .rounded)).kerning(1)
            }
            .foregroundColor(.white)
            .frame(width: 140, height: 80)
            .background(Color.black)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(white: 0.3), lineWidth: 1))
        }
    }
}
