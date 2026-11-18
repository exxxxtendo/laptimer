import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TrackStore
    @EnvironmentObject private var location: LocationService
    @EnvironmentObject private var records: RecordsStore

    @State private var showTracks = false
    @State private var showRecords = false
    @State private var sessionTarget: SessionTarget?
    @State private var heroPulse = false

    private struct SessionTarget: Identifiable {
        let id = UUID()
        let track: Track?
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                header
                    .padding(.top, 8)

                Spacer(minLength: 12)

                hero

                Spacer(minLength: 12)

                if store.lastTrack != nil {
                    quickStart
                        .padding(.bottom, 12)
                }

                menuRow
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 20)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            location.requestPermission()
            records.migrateLegacy(tracks: store.tracks)
            withAnimation(Animation.easeOut(duration: 2.4).repeatForever(autoreverses: false)) {
                heroPulse = true
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
            VStack(alignment: .leading, spacing: 1) {
                Text("GUCCI")
                    .font(Theme.number(17, weight: .black))
                    .kerning(3)
                    .foregroundColor(.white)
                Text("RACING")
                    .font(Theme.label(9))
                    .kerning(4)
                    .foregroundColor(Theme.accent)
            }

            Spacer()

            Button(action: { location.requestPermission() }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(gpsColor)
                        .frame(width: 6, height: 6)
                    Text(gpsText)
                        .font(Theme.label(10))
                        .kerning(0.6)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.white.opacity(0.07)))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var gpsColor: Color {
        if !location.isAuthorized { return Theme.negative }
        return location.hasFix ? Theme.positive : Theme.warning
    }

    private var gpsText: String {
        if !location.isAuthorized { return "НЕТ GPS" }
        if location.hasFix {
            return "GPS ±\(Int(location.horizontalAccuracy.rounded())) М"
        }
        return "ПОИСК GPS"
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 20) {
            Button(action: { start(nil) }) {
                ZStack {
                    Circle()
                        .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                        .frame(width: 250, height: 250)
                        .scaleEffect(heroPulse ? 1.07 : 0.93)
                        .opacity(heroPulse ? 0 : 0.9)

                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Theme.accent.opacity(0.22), Color.clear]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 130
                            )
                        )
                        .frame(width: 250, height: 250)

                    Image("BeeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 198, height: 198)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.accent.opacity(0.55), lineWidth: 2))
                        .shadow(color: Theme.accent.opacity(0.35), radius: 26, x: 0, y: 0)
                }
            }
            .buttonStyle(PlainButtonStyle())

            VStack(spacing: 4) {
                Text("СВОБОДНЫЙ ЗАЕЗД")
                    .font(Theme.number(15, weight: .black))
                    .kerning(2)
                    .foregroundColor(.white)
                Text("секундомер и телеметрия")
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textTertiary)
            }
        }
    }

    // MARK: - Quick start

    private var quickStart: some View {
        Group {
            if let track = store.lastTrack {
                Button(action: { start(track) }) {
                    Panel(cornerRadius: 18) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("ПОСЛЕДНЯЯ ТРАССА")
                                    .font(Theme.label(9))
                                    .kerning(1)
                                    .foregroundColor(Theme.textTertiary)
                                Text(track.name)
                                    .font(Theme.body(16, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(quickStartSubtitle(track))
                                    .font(Theme.body(11))
                                    .foregroundColor(Theme.textTertiary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.accent)
                        }
                        .padding(14)
                    }
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
        HStack(spacing: 12) {
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
                     tint: Theme.warning,
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
            // Даём шиту закрыться, иначе fullScreenCover не покажется.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                sessionTarget = target
            }
        } else {
            sessionTarget = target
        }
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
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
                Spacer(minLength: 0)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(value)
                        .font(Theme.number(26, weight: .black))
                        .foregroundColor(.white)
                    Text(caption)
                        .font(Theme.body(11))
                        .foregroundColor(Theme.textTertiary)
                }
                Text(title)
                    .font(Theme.label(10))
                    .kerning(1.2)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
