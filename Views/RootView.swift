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
            // Глубокий бордовый градиент (Gucci style)
            LinearGradient(colors: [Color(red: 0.3, green: 0.0, blue: 0.0), Color(red: 0.1, green: 0.0, blue: 0.0), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Шахматная полоса (по центру)
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
            
            // Центральная кнопка
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
                        .shadow(color: .black.opacity(0.9), radius: 25, x: 0, y: 10)
                        .overlay(
                            Circle().stroke(LinearGradient(colors: [.gray.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                        )
                    
                    // Если картинки нет, покажет иконку машины
                    Image("BeeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
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

// Кнопка меню
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
                    .kerning(2)
            }
            .foregroundColor(.white)
            .frame(width: 140, height: 80)
            .background(Color.black)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.5), lineWidth: 1.5)
            )
            .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

// Идеально ровная шахматная полоса
struct CheckeredStripe: View {
    var body: some View {
        GeometryReader { geo in
            let squareSize = geo.size.height // Квадраты будут размером с высоту полосы
            let count = Int(geo.size.width / squareSize) + 2
            
            HStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { i in
                    Rectangle()
                        .fill(i % 2 == 0 ? Color.white : Color.black)
                        .frame(width: squareSize)
                }
            }
            .frame(width: geo.size.width, alignment: .center)
            .offset(x: -squareSize) // Центрируем
        }
    }
}
