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
                
                // Идеальная шахматная полоса
                CheckeredStripe()
                    .frame(height: 60)
                
                Spacer()
                
                // Нижние кнопки
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
            
            // Кнопка по центру (без черной подложки)
            Button {
                if let lastTrack = store.tracks.last {
                    activeSession = lastTrack
                } else {
                    showTracks = true
                }
            } label: {
                Image("BeeLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .clipShape(Circle()) // Делаем картинку круглой
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
                    .stroke(Color(white: 0.3), lineWidth: 1)
            )
        }
    }
}

// Идеальная шахматная полоса (клетки всегда квадратные)
struct CheckeredStripe: View {
    var body: some View {
        GeometryReader { geo in
            let squareSize = geo.size.height // Размер клетки = высоте полосы
            let count = Int(geo.size.width / squareSize) + 1 // Считаем, сколько клеток влезет
            
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    Rectangle()
                        .fill(i % 2 == 0 ? Color.white : Color.black)
                        .frame(width: squareSize, height: squareSize)
                }
            }
            .frame(width: geo.size.width, alignment: .center)
            .offset(x: squareSize / 2) // Центрируем, чтобы края были ровные
        }
        .clipped() // Обрезаем всё, что вылезло за экран
    }
}
