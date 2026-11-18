import SwiftUI

struct SessionView: View {
    let track: Track?

    @EnvironmentObject private var store: TrackStore
    @EnvironmentObject private var location: LocationService
    @EnvironmentObject private var records: RecordsStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var engine: LapTimerEngine
    @State private var showSummary = false
    @State private var completedSession: SessionResult?
    @State private var showStopConfirmation = false
    @State private var recenterToken = 0

    init(track: Track?) {
        self.track = track
        _engine = StateObject(wrappedValue: LapTimerEngine(track: track))
    }

    private var followsUser: Bool {
        engine.isFreeMode ? false : true
    }

    var body: some View {
        ZStack {
            RaceMapView(track: track, followsUser: followsUser, recenterToken: recenterToken)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                topBar

                if engine.isFreeMode {
                    Spacer()
                } else {
                    Spacer(minLength: 0)
                    lapStrip
                }

                Spacer()

                bottomControls
            }
            .padding(.horizontal, Theme.screenPadding)
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: startSession)
        .onDisappear(perform: finishSession)
        .onChange(of: location.lastLocation) { newLocation in
            guard let location = newLocation else { return }
            engine.process(location)
        }
        .confirmationDialog(
            "Завершить заезд?",
            isPresented: $showStopConfirmation,
            titleVisibility: .visible
        ) {
            Button(engine.hasData ? "Сохранить и выйти" : "Выйти", role: .destructive) {
                stopSession()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            if engine.hasData {
                Text("Кругов зафиксировано: \(engine.lapCount)")
            } else {
                Text("Ни одного круга не зафиксировано.")
            }
        }
        .sheet(isPresented: $showSummary, onDismiss: { dismiss() }) {
            if let session = completedSession {
                SummaryView(session: session)
                    .environmentObject(records)
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            MapControlButton(icon: "xmark") { showStopConfirmation = true }

            Spacer(minLength: 8)

            HStack(spacing: 7) {
                Circle()
                    .fill(location.hasFix ? Theme.positive : Theme.warning)
                    .frame(width: 7, height: 7)
                Text(track?.name ?? "Свободный заезд")
                    .font(Theme.body(13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color.black.opacity(0.55)))
            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))

            Spacer(minLength: 8)

            MapControlButton(icon: "location.fill") {
                recenterToken += 1
            }
        }
    }

    // MARK: - Список кругов над HUD

    private var lapStrip: some View {
        Group {
            if engine.laps.isEmpty {
                EmptyView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(engine.laps.suffix(8).reversed()) { lap in
                            LapChip(lap: lap, isBest: lap.time == engine.bestLapTime)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - Низ: HUD и кнопки

    private var bottomControls: some View {
        VStack(spacing: 12) {
            if engine.isFreeMode {
                FreeHUD(
                    state: engine.state,
                    currentLapTime: engine.currentLapTime,
                    speedKph: engine.speedKph,
                    distanceMeters: engine.distanceMeters,
                    topSpeedKph: engine.topSpeedKph,
                    lapCount: engine.lapCount,
                    bestLapTime: engine.bestLapTime
                )

                Button(action: { engine.toggleFreeSession() }) {
                    Text(freeButtonTitle)
                        .font(Theme.number(16, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                                .fill(freeButtonColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
            } else {
                TrackHUD(
                    state: engine.state,
                    currentLapTime: engine.currentLapTime,
                    lastLapTime: engine.lastLapTime,
                    bestLapTime: engine.bestLapTime,
                    predictedLapTime: engine.predictedLapTime,
                    delta: engine.delta,
                    lapNumber: engine.lapCount,
                    speedKph: engine.speedKph,
                    hasReference: engine.referenceBest != nil
                )
            }
        }
    }

    private var freeButtonTitle: String {
        switch engine.state {
        case .idle, .armed:
            return "СТАРТ"
        case .running:
            return "ПАУЗА"
        case .paused:
            return "ПРОДОЛЖИТЬ"
        }
    }

    private var freeButtonColor: Color {
        switch engine.state {
        case .idle, .armed:
            return Theme.accent
        case .running:
            return Theme.warning.opacity(0.85)
        case .paused:
            return Theme.positive
        }
    }

    // MARK: - Логика

    private func startSession() {
        location.start()
        let reference = track.flatMap { records.record(for: $0.id)?.bestLap }
        engine.start(from: location.lastLocation, reference: reference)
    }

    private func finishSession() {
        engine.stop()
        location.stop()
    }

    private func stopSession() {
        engine.stop()

        guard engine.hasData else {
            dismiss()
            return
        }

        var session = SessionResult(
            trackID: track?.id,
            trackName: track?.name ?? "Свободный заезд"
        )
        session.laps = engine.laps
        completedSession = session
        showSummary = true
    }
}

// MARK: - Чип круга

struct LapChip: View {
    let lap: Lap
    let isBest: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text("\(lap.index)")
                .font(Theme.label(10))
                .foregroundColor(Theme.textTertiary)
                .frame(width: 16)
            Text(Fmt.lap(lap.time))
                .font(Theme.number(13, weight: .bold))
                .foregroundColor(isBest ? Theme.positive : .white)
                .monospacedDigit()
            if isBest {
                Image(systemName: "crown.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.warning)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(Color.black.opacity(0.55))
        )
        .overlay(Capsule().stroke(isBest ? Theme.positive.opacity(0.4) : Theme.stroke, lineWidth: 1))
    }
}
