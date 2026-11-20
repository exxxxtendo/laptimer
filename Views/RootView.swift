import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TrackStore
    @EnvironmentObject private var location: LocationService
    @EnvironmentObject private var records: RecordsStore

    @State private var showTracks = false
    @State private var showRecords = false
    @State private var sessionTarget: SessionTarget?
    @State private var heroPulse = false
    @State private var logoGlow = false

    private struct SessionTarget: Identifiable {
        let id = UUID()
        let track: Track?
    }

    var body: some View {
        ZStack {
            AppBackground()

            GeometryReader { geo in
                let safeArea = geo.safeAreaInsets
                let metrics = HomeMetrics(size: geo.size, safeArea: safeArea)

                VStack(spacing: 0) {
                    header
                        .padding(.top, max(metrics.topPadding, safeArea.top + 4))

                    Spacer(minLength: 8)

                    hero(diameter: metrics.heroDiameter)

                    Spacer(minLength: 8)

                    if store.lastTrack != nil {
                        quickStart
                            .padding(.bottom, 10)
                    }

                    menuRow
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, max(metrics.bottomPadding, safeArea.bottom + 8))
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            location.requestPermission()
            records.migrateLegacy(tracks: store.tracks)
            withAnimation(Animation.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                heroPulse = true
            }
            withAnimation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                logoGlow = true
            }
        }
        .sheet(isPresented: $showTracks) {
            TracksListView(onStart: start)
                .environmentObject(store)
                .environmentObject(records)
                .environmentObject(location)
        }
        .sheet(isPresented: $showRecords) {
            RecordsListView()
                .environmentObject(records)
                .environmentObject(store)
        }
        .fullScreenCover(item: $sessionTarget) { target in
            SessionView(track: target.track)
                .environmentObject(store)
                .environmentObject(location)
                .environmentObject(records)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text("GUCCI")
                    .font(Theme.display(24))
                    .kerning(1)
                    .foregroundColor(.white)
                    .shadow(color: Theme.accent, radius: logoGlow ? 18 : 8)
                Text("RACING")
                    .font(Theme.label(10))
                    .kerning(5.5)
                    .foregroundColor(Theme.accentLemon)
            }

            Spacer()

            Button(action: { location.requestPermission() }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(gpsColor)
                        .frame(width: 7, height: 7)
                        .shadow(color: gpsColor, radius: 5)
                    Text(gpsText)
                        .font(Theme.label(9))
                        .kerning(0.8)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.surface.opacity(0.9)))
                .overlay(Capsule().stroke(Theme.strokeStrong, lineWidth: 1.5))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var gpsColor: Color {
        if !location.isAuthorized { return Theme.negative }
        return location.hasFix ? Theme.positive : Theme.accentLemon
    }

    private var gpsText: String {
        if !location.isAuthorized { return "НЕТ GPS" }
        if location.hasFix {
            return "GPS ±\(Int(location.horizontalAccuracy.rounded())) М"
        }
        return "ПОИСК GPS"
    }

    // MARK: - Hero

    /// Логотип и кольца масштабируются под доступную высоту экрана.
    private func hero(diameter: CGFloat) -> some View {
        VStack(spacing: 14) {
            Button(action: { start(nil) }) {
                ZStack {
                    // Внешнее неоновое кольцо-пульс.
                    Circle()
                        .stroke(Theme.accent.opacity(0.55), lineWidth: 2)
                        .frame(width: diameter * 0.92, height: diameter * 0.92)
                        .scaleEffect(heroPulse ? 1.12 : 0.88)
                        .opacity(heroPulse ? 0 : 0.9)

                    Circle()
                        .stroke(Theme.accentLemon.opacity(0.35), lineWidth: 1.5)
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(heroPulse ? 1.05 : 0.95)

                    // Свечение под лого.
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Theme.accent.opacity(0.55),
                                    Theme.accentViolet.opacity(0.22),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: diameter * 0.52
                            )
                        )
                        .frame(width: diameter * 0.97, height: diameter * 0.97)
                        .scaleEffect(logoGlow ? 1.06 : 0.96)

                    Image("BeeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: diameter * 0.71, height: diameter * 0.71)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(Theme.accentLemon, lineWidth: 2.5)
                        )
                        .shadow(color: Theme.accent.opacity(0.9), radius: 30)
                }
            }
            .buttonStyle(PlainButtonStyle())

            VStack(spacing: 3) {
                Text("СВОБОДНЫЙ ЗАЕЗД")
                    .font(Theme.number(16, weight: .black))
                    .kerning(2.4)
                    .foregroundColor(.white)
                    .shadow(color: Theme.accent, radius: 12)
                Text("секундомер · телеметрия")
                    .font(Theme.body(12, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
            }
        }
    }

    // MARK: - Quick start

    private var quickStart: some View {
        Group {
            if let track = store.lastTrack {
                Button(action: { start(track) }) {
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Theme.accentLemon)
                            .frame(width: 4)
                            .shadow(color: Theme.accentLemon, radius: 8)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("ПОСЛЕДНЯЯ ТРАССА")
                                .font(Theme.label(9))
                                .kerning(1.4)
                                .foregroundColor(Theme.textTertiary)
                            Text(track.name)
                                .font(Theme.body(16, weight: .black))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(quickStartSubtitle(track))
                                .font(Theme.body(11, weight: .semibold))
                                .foregroundColor(Theme.textTertiary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 6)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(Theme.accentLemon)
                            .shadow(color: Theme.accentLemon, radius: 8)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.surface.opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.strokeStrong, lineWidth: 1.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func quickStartSubtitle(_ track: Track) -> String {
        let length = Fmt.distance(track.displayLength)
        if let record = records.record(for: track.id) {
            return "\(length) · рекорд \(Fmt.lap(record.bestLap))"
        }
        return "\(length) · рекорда пока нет"
    }

    // MARK: - Menu

    private var menuRow: some View {
        HStack(spacing: 10) {
            MenuTile(title: "ТРАССЫ",
                     value: "\(store.tracks.count)",
                     caption: "в гараже",
                     icon: "map.fill",
                     tint: Theme.accent,
                     action: { showTracks = true })

            MenuTile(title: "РЕКОРДЫ",
                     value: "\(records.trackCount)",
                     caption: "\(records.totalLaps) кругов",
                     icon: "trophy.fill",
                     tint: Theme.accentLemon,
                     action: { showRecords = true })
        }
    }

    // MARK: - Navigation

    private func start(_ track: Track?) {
        if let track = track {
            store.markUsed(track)
        }

        let sheetIsOpen = showTracks || showRecords
        showTracks = false
        showRecords = false

        let target = SessionTarget(track: track)
        if sheetIsOpen {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                sessionTarget = target
            }
        } else {
            sessionTarget = target
        }
    }
}

// MARK: - Метрики главного экрана

/// Считает размеры главного экрана под конкретную высоту устройства,
/// чтобы на iPhone SE/8 контент не заезжал под статус-бар и не обрезался снизу.
private struct HomeMetrics {
    let heroDiameter: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat

    init(size: CGSize, safeArea: EdgeInsets) {
        let usableHeight = size.height - safeArea.top - safeArea.bottom

        // Высота постоянных блоков: шапка, подписи, плитки меню.
        let headerHeight: CGFloat = 46
        let captionHeight: CGFloat = 40
        let menuHeight: CGFloat = 132
        let quickStartHeight: CGFloat = 84
        let gaps: CGFloat = 40

        let reserved = headerHeight + captionHeight + menuHeight + quickStartHeight + gaps
        let available = max(usableHeight - reserved, 140)

        // Логотип занимает примерно 62% свободного места, но в разумных пределах.
        let computed = min(available * 0.62, 268)
        heroDiameter = max(computed, 150)

        topPadding = safeArea.top > 0 ? 6 : 12
        bottomPadding = 16
    }
}

// MARK: - Menu tile

struct MenuTile: View {
    let title: String
    let value: String
    let caption: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(tint)
                    .shadow(color: tint.opacity(0.9), radius: 8)
                Spacer(minLength: 0)
                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    Text(value)
                        .font(Theme.number(30, weight: .black))
                        .foregroundColor(.white)
                    Text(caption)
                        .font(Theme.body(10, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)
                }
                Text(title)
                    .font(Theme.label(10))
                    .kerning(1.6)
                    .foregroundColor(tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(0.45), lineWidth: 1.5)
            )
            .shadow(color: tint.opacity(0.22), radius: 14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
