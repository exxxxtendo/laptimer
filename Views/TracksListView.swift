import SwiftUI

/// Список трасс в гараже: карточки с превью, рекордами и действиями.
struct TracksListView: View {
    let onStart: (Track) -> Void

    @EnvironmentObject private var store: TrackStore
    @EnvironmentObject private var records: RecordsStore
    @Environment(\.dismiss) private var dismiss

    @State private var renamingTrack: Track?
    @State private var newName = ""
    @State private var showRecorder = false
    @State private var showManualRecorder = false

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        sectionLabel
                        tracksSection
                        actionsSection
                    }
                    .padding(Theme.screenPadding)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showRecorder) {
            RecordTrackView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showManualRecorder) {
            ManualTrackView()
                .environmentObject(store)
        }
        .sheet(item: $renamingTrack) { track in
            RenameSheet(name: $newName) {
                store.rename(track, to: newName)
                renamingTrack = nil
            } onCancel: {
                renamingTrack = nil
            }
            .onAppear {
                newName = track.name
            }
        }
        .onAppear(perform: loadMissingGeometry)
    }

    // MARK: - Секции

    private func loadMissingGeometry() {
        for track in store.tracks where track.needsRouteGeometry {
            RouteGeometryLoader.load(for: track) { updated in
                guard let updated = updated else { return }
                store.update(updated)
            }
        }
    }

    private var sectionLabel: some View {
        NeonHeading(text: "Сохранённые трассы")
            .padding(.top, 4)
    }

    private var tracksSection: some View {
        Group {
            if store.tracks.isEmpty {
                Panel {
                    EmptyState(
                        icon: "map",
                        title: "Гараж пуст",
                        message: "Запишите трассу по GPS или постройте её вручную по карте."
                    )
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(store.tracks) { track in
                        TrackCard(
                            track: track,
                            best: records.record(for: track.id)?.bestLap,
                            onStart: { start(track) },
                            onRename: {
                                newName = track.name
                                renamingTrack = track
                            },
                            onDelete: { store.delete(track) }
                        )
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button(action: { showRecorder = true }) {
                Label("Записать трассу", systemImage: "record.circle")
                    .font(Theme.number(15, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(action: { showManualRecorder = true }) {
                Label("Построить по карте", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(Theme.number(15, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func start(_ track: Track) {
        onStart(track)
    }
}

// MARK: - Карточка трассы

struct TrackCard: View {
    let track: Track
    let best: TimeInterval?
    let onStart: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Menu {
            Button(action: onStart) {
                Label("Ехать", systemImage: "flag.checkered")
            }
            Button(action: onRename) {
                Label("Переименовать", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Удалить", systemImage: "trash")
            }
        } label: {
            cardBody
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var cardBody: some View {
        VStack(spacing: 0) {
            TrackSnapshotView(track: track)
                .frame(height: 108)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(track.name)
                        .font(Theme.body(16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if let best = best {
                        Text(Fmt.lap(best))
                            .font(Theme.number(14, weight: .heavy))
                            .foregroundColor(Theme.positive)
                            .monospacedDigit()
                    } else {
                        Text("нет рекорда")
                            .font(Theme.body(11))
                            .foregroundColor(Theme.textTertiary)
                    }
                }

                HStack(spacing: 6) {
                    Badge(text: Fmt.distance(track.displayLength))
                    Badge(text: track.points.count == 2 ? "по дорогам" : "\(track.points.count) точек")
                    if track.isLoop {
                        Badge(text: "кольцо")
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

// MARK: - Переименование

struct RenameSheet: View {
    let save: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    @Binding var name: String

    init(name: Binding<String>, save: @escaping () -> Void, onCancel: @escaping () -> Void) {
        _name = name
        self.save = save
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Название трассы", text: $name)
                    .font(Theme.body(15, weight: .medium))
            }
            .navigationTitle("Переименовать")
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }
}
