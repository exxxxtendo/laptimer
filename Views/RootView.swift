import SwiftUI

struct RootView: View {
    @EnvironmentObject var location: LocationService
    @EnvironmentObject var store: TrackStore
    @EnvironmentObject var recordsStore: RecordsStore
    
    @State private var showTracks = false
    @State private var showRecords = false
    @State private var activeSession: Track?

    var body: some View {
        ZStack {
            // Темно-красный градиентный фон
            LinearGradient(colors: [Color(red: 0.2, green: 0.0, blue: 0.0), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // Шахматная полоса
            VStack {
                Spacer()
                CheckeredStripe()
                    .frame(height: 40)
                Spacer()
            }
            
            VStack {
                Spacer()
                
                // Центральная кнопка с пчелой
                Button {
                    if let lastTrack = store.tracks.last {
                        activeSession = lastTrack
                    } else {
                        showTracks = true
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 200, height: 200)
                            .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: 10)
                        
                        // Если картинки нет, покажет иконку машины
                        Image("BeeLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
                
                // Нижние кнопки
                HStack(spacing: 20) {
                    MenuButton(title: "TRACKS", icon: "map.fill") {
                        showTracks = true
                    }
                    
                    MenuButton(title: "RECORDS", icon: "trophy.fill") {
                        showRecords = true
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear { location.requestPermission() }
        .sheet(isPresented: $showTracks) {
            TracksListView()
        }
        .sheet(isPresented: $showRecords) {
            RecordsListView()
        }
        .fullScreenCover(item: $activeSession) { track in
            SessionView(track: track)
        }
    }
}

// Компонент кнопки меню
struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(width: 120, height: 60)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// Компонент шахматной полосы
struct CheckeredStripe: View {
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(0..<Int(geo.size.width / 20), id: \.self) { i in
                    Rectangle()
                        .fill(i % 2 == 0 ? Color.white : Color.black)
                        .frame(width: 20)
                }
            }
        }
    }
}
