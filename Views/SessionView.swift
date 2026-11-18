import SwiftUI

struct SessionView: View {
    let track: Track?
    @EnvironmentObject var location: LocationService
    @EnvironmentObject var recordsStore: RecordsStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine = LapTimerEngine()
    @State private var showSummary = false
    
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
                dismiss()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(.trailing, 20)
            .padding(.bottom, 145)
        }
        .onAppear {
            location.start()
            
            // ПОДГРУЖАЕМ РЕКОРД ТРАССЫ ПРИ СТАРТЕ
            let existingBest = track?.name != nil ? recordsStore.records[track!.name] : nil
            engine.start(with: track, initialBest: existingBest)
        }
        .onDisappear {
            engine.stop()
            location.stop()
        }
        .onChange(of: location.lastLocation) { loc in
            guard let loc = loc else { return }
            engine.process(loc)
        }
        .onChange(of: engine.isTiming) { isTiming in
            if !isTiming && engine.lastLapTime != nil {
                showSummary = true
                if let best = engine.bestLapTime, let trackName = track?.name {
                    recordsStore.addRecord(trackName: trackName, time: best)
                }
            }
        }
        .sheet(isPresented: $showSummary) { summarySheet }
    }

    private var topBar: some View {
        HStack {
            Button { 
                engine.stop()
                location.stop()
                dismiss() 
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.bold))
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(location.speedKph > 0 ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(track?.name ?? "Free Drive")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
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
            Button("Вернуться на карту") { showSummary = false }
                .buttonStyle(.borderedProminent).padding(.bottom)
        }.padding()
    }
}
