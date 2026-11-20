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

            // Затемнение низа, чтобы HUD читался на любой карте.
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Theme.background.opacity(0.85), Theme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 340)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 10) {
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
            "Закончить заезд?",
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

    // MARK: - Верхняя панель

    private var topBar: some View {
        HStack(spacing: 10) {
            MapControlButton(icon: "xmark") { showStopConfirmation = true }

            Spacer(minLength: 6)

            HStack(spacing: 7) {
                Circle()
                    .fill(location.hasFix ? Theme.positive : Theme.accentLemon)
                    .frame(width: 8, height: 8)
                    .shadow(color: (location.hasFix ? Theme.positive : Theme.accentLemon), radius: 6)
                Text(track?.name ?? "Свободный заезд")
                    .font(Theme.body(13, weight: .black))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(Theme.surface.opacity(0.92)))
            .overlay(Capsule().stroke(Theme.strokeStrong, lineWidth: 1.5))

            Spacer(minLength: 6)

            MapControlButton(icon: "location.fill", tint: Theme.accentCyan) {
                recenterToken += 1
            }
        }
    }

    // MARK: - Полоска кругов

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

    // MARK: - Низ

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

                HStack(spacing: 10) {
                    Button(action: { engine.toggleFreeSession() }) {
                        Text(freeButtonTitle)
                            .font(Theme.number(16, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                                    .fill(freeButtonColor)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                            )
                            .shadow(color: freeButtonColor.opacity(0.6), radius: 16)
                    }

                    if engine.state == .running {
                        Button(action: { engine.markLap() }) {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                                        .fill(Theme.accentLemon)
                                )
                                .shadow(color: Theme.accentLemon.opacity(0.6), radius: 14)
                        }
                    }
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

                Button(action: { showStopConfirmation = true }) {
                    Text("ЗАКОНЧИТЬ ЗАЕЗД")
                        .font(Theme.number(15, weight: .black))
                        .kerning(1.2)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                                .fill(Theme.surfaceElevated)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                                .stroke(Theme.strokeStrong, lineWidth: 1.5)
                        )
                }
            }
        }
        .padding(.bottom, 8)
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
            return Theme.accentWarm
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
                .foregroundColor(isBest ? Theme.background : Theme.textTertiary)
                .frame(width: 18, height: 18)
                .background(Circle().fill(isBest ? Theme.accentLemon : Theme.surfaceElevated))
            Text(Fmt.lap(lap.time))
                .font(Theme.number(13, weight: .black))
                .foregroundColor(isBest ? Theme.accentLemon : .white)
                .monospacedDigit()
            if isBest {
                Image(systemName: "crown.fill")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Theme.accentLemon)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.surface.opacity(0.94)))
        .overlay(Capsule().stroke(isBest ? Theme.accentLemon.opacity(0.8) : Theme.stroke, lineWidth: 1.5))
    }
}
