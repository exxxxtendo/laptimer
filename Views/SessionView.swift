import SwiftUI

struct SessionView: View {
    let track: Track
    @EnvironmentObject var location: LocationService
    @EnvironmentObject var recordsStore: RecordsStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine = LapTimerEngine()
    @State private var showSummary = false
    @State private var showTracks = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RaceMapView(track: track).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                HUDView(
                    current: engine.currentLapTime,
                    last: engine.lastLapTime,
                    best: engine.bestLapTime,
                    delta: engine.delta,
                    laps: engine.lapCount,
                    speedKph: location.speedKph
                )
            }
            
            Button {
                engine.stop()
                location.stop()
                showTracks = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black)
                    .clipShape(Circle())
            }
            .padding(.trailing, 20)
            .padding(.bottom, 145)
        }
        .onAppear {
            location.start()
            engine.start(with: track)
        }
        .onDisappear {
            engine.stop()
            location.stop()
        }
        .onChange(of: location.lastLocation) { loc in
            guard let loc = loc else { return }
            engine.process(loc)
        }
        // Следим за состоянием таймера (isTiming)
        .onChange(of: engine.isTiming) { isTiming in
            // Если таймер остановился (доехали до финиша) и есть результат
            if !isTiming && engine.lastLapTime != nil {
                showSummary = true
                if let best = engine.bestLapTime {
                    recordsStore.addRecord(trackName: track.name, time: best)
                }
            }
        }
        .sheet(isPresented: $showSummary) { summarySheet }
        .sheet(isPresented: $showTracks) { TracksListView() }
    }

    private var topBar: some View {
        HStack {
            Button { engine.stop(); location.stop(); dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.bold))
                    .padding(12)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(location.speedKph > 0 ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(track.name)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.7))
            .clipShape(Capsule())
            
            Spacer()
            
            // Кнопка ручного старта
            Button { 
                engine.manualStart() 
            } label: {
                Image(systemName: "flag.fill")
                    .font(.title3.weight(.bold))
                    .padding(12)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(engine.isTiming ? .green : .white)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var summarySheet: some View {
        VStack(spacing: 16) {
            Text("Итоги заезда").font(.title2.weight(.bold))
            if let last = engine.lastLapTime {
                VStack(spacing: 4) {
                    Text("Время круга").font(.caption).foregroundColor(.secondary)
                    Text(Fmt.lap(last)).font(.system(size: 48, weight: .bold, design: .rounded)).monospacedDigit()
                }
            } else {
                Text("Время не зафиксировано").foregroundColor(.secondary)
            }
            Text("Всего кругов: \(engine.lapCount)").font(.headline)
            List(engine.laps) { lap in
                HStack {
                    Text(Fmt.lap(lap.time)).monospacedDigit()
                    Spacer()
                    Text(lap.date, style: .time).foregroundColor(.secondary)
                }
            }.listStyle(.plain)
            
            Button("Вернуться на карту") { 
                showSummary = false 
            }
            .buttonStyle(.borderedProminent).padding(.bottom)
        }.padding()
    }
}
