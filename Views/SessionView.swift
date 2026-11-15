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
        ZStack {
            RaceMapView(track: track).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                // HUD теперь сам занимает нужное пространство
                HUDView(
                    current: engine.currentLapTime,
                    last: engine.lastLapTime,
                    best: engine.bestLapTime,
                    delta: engine.delta,
                    laps: engine.lapCount,
                    speedKph: location.speedKph
                )
            }
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
        .onChange(of: engine.isRunning) { isRunning in
            if !isRunning && engine.lastLapTime != nil {
                location.stop()
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
            // Кнопка закрытия (Крестик)
            Button { engine.stop(); location.stop(); dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            Spacer()
            
            // Название трассы по центру
            Text(track.name)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
            
            Spacer()
            
            // Кнопка плюс (выбор трасс) и Флаг (стоп)
            HStack(spacing: 12) {
                Button { engine.stop(); location.stop(); showTracks = true } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                
                Button { engine.stop(); location.stop(); showSummary = true } label: {
                    Image(systemName: "flag.checkered")
                        .font(.title3.weight(.semibold))
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var summarySheet: some View {
        VStack(spacing: 16) {
            Text("Итоги сессии").font(.title2.weight(.bold))
            if let best = engine.bestLapTime {
                VStack(spacing: 4) {
                    Text("Результат").font(.caption).foregroundColor(.secondary)
                    Text(Fmt.lap(best)).font(.system(size: 48, weight: .bold, design: .rounded)).monospacedDigit()
                }
            } else {
                Text("Время не зафиксировано").foregroundColor(.secondary)
            }
            Text("Всего заездов: \(engine.lapCount)").font(.headline)
            List(engine.laps) { lap in
                HStack {
                    Text(Fmt.lap(lap.time)).monospacedDigit()
                    Spacer()
                    Text(lap.date, style: .time).foregroundColor(.secondary)
                }
            }.listStyle(.plain)
            Button("Закрыть") { dismiss() }.buttonStyle(.borderedProminent).padding(.bottom)
        }.padding()
    }
}
