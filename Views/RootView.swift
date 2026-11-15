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
            // Градиент
            LinearGradient(colors: [Color(red: 0.25, green: 0.0, blue: 0.0), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                CheckeredStripe()
                    .frame(height: 40) // Высота полосы
                Spacer()
                
                HStack(spacing: 30) {
                    MenuButton(title: "TRACKS", icon: "map.fill") { showTracks = true }
                    MenuButton(title: "RECORDS", icon: "trophy.fill") { showRecords = true }
                }
                .padding(.bottom, 50)
            }
            
            Button {
                if let lastTrack = store.tracks.last { activeSession = lastTrack } else { showTracks = true }
            } label: {
                ZStack {
                    Circle().fill(Color.black).frame(width: 220, height: 220)
                    Image("BeeLogo").resizable().scaledToFit().frame(width: 140, height: 140).clipShape(Circle())
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

// Идеальная мелкая шахматная полоса
struct CheckeredStripe: View {
    var body: some View {
        GeometryReader { geo in
            let squareSize: CGFloat = 40
            let count = Int(geo.size.width / squareSize) + 2
            
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    Rectangle()
                        .fill(i % 2 == 0 ? Color.white : Color.black)
                        .frame(width: squareSize, height: squareSize)
                }
            }
            .offset(x: -squareSize / 2) // Центрируем
        }
        .clipped()
    }
}
