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
            // Глубокий бордовый градиент
            LinearGradient(colors: [Color(red: 0.25, green: 0.0, blue: 0.0), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                CheckeredStripe()
                    .frame(height: 60)
                Spacer()
                
                // Кнопки снизу
                HStack(spacing: 30) {
                    MenuButton(title: "TRACKS", icon: "map.fill") {
                        showTracks = true
                    }
                    
                    MenuButton(title: "RECORDS", icon: "trophy.fill") {
                        showRecords = true
                    }
                }
                .padding(.bottom, 50)
            }
            
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
                        .frame(width: 220, height: 220)
                        .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: 10)
                    
                    Image("BeeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                }
            }
        }
        .onAppear { location.requestPermission() }
        .sheet(isPresented: $showTracks) { TracksListView() }
        .sheet(isPresented: $showRecords) { RecordsListView() }
        .fullScreenCover(item: $activeSession) { track in SessionView(track: track) }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .kerning(1)
            }
            .foregroundColor(.white)
            .frame(width: 140, height: 80)
            .background(Color.black)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
            )
        }
    }
}

// Идеально ровная шахматная полоса (квадраты строго 60x60)
struct CheckeredStripe: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<20, id: \.self) { i in
                Rectangle()
                    .fill(i % 2 == 0 ? Color.white : Color.black)
                    .frame(width: 60, height: 60)
            }
        }
        .offset(x: -30) // Центрируем, чтобы не было обрезанных краев
    }
}
