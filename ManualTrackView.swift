import SwiftUI
import CoreLocation
import MapKit

/// Ручное создание трассы: тап по карте ставит старт, второй тап — финиш.
/// Линия трека строится маршрутизатором Apple по дорогам.
struct ManualTrackView: View {
    @EnvironmentObject private var store: TrackStore
    @Environment(\.dismiss) private var dismiss

    @State private var path: [CLLocationCoordinate2D] = []
    @State private var showNameSheet = false
    @State private var trackName = ""

    var body: some View {
        ZStack {
            ManualTrackMapView(path: path) { coordinate in
                handleTap(coordinate)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomPanel
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showNameSheet) {
            nameSheet
        }
    }

    // MARK: - Верх

    private var topBar: some View {
        HStack {
            MapControlButton(icon: "xmark") { dismiss() }
            Spacer()
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 8)
    }

    // MARK: - Низ

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            hint

            HStack(spacing: 12) {
                MapControlButton(icon: "arrow.uturn.backward") {
                    withAnimation { path.removeAll() }
                    Haptics.light()
                }
                .frame(width: 56, height: 56)

                Button(action: save) {
                    Text("СОХРАНИТЬ")
                        .font(Theme.number(16, weight: .heavy))
                        .foregroundColor(path.count == 2 ? .white : Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(PrimaryButtonStyle(color: path.count == 2 ? Theme.accent : Theme.surfaceElevated))
                .disabled(path.count != 2)
            }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.bottom, 20)
    }

    private var hint: some View {
        Text(hintText)
            .font(Theme.body(13, weight: .semibold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.black.opacity(0.6)))
            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
    }

    private var hintText: String {
        switch path.count {
        case 0:
            return "Нажмите на карту, чтобы поставить СТАРТ"
        case 1:
            return "Теперь поставьте ФИНИШ"
        default:
            return "Маршрут построен по дорогам"
        }
    }

    // MARK: - Логика

    private func handleTap(_ coordinate: CLLocationCoordinate2D) {
        guard path.count < 2 else { return }
        withAnimation { path.append(coordinate) }
        Haptics.light()
    }

    private func save() {
        guard let first = path.first, let last = path.last else { return }
        trackName = "Трасса \(store.tracks.count + 1)"
        pendingSave = [first, last]
        showNameSheet = true
    }

    @State private var pendingSave: [CLLocationCoordinate2D] = []

    private var nameSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Название трассы", text: $trackName)
                        .font(Theme.body(15, weight: .medium))
                } header: {
                    Text("Круг будет считаться между стартом и финишем")
                }
            }
            .navigationTitle("Сохранить")
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { showNameSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { commitSave() }
                        .disabled(trackName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    private func commitSave() {
        guard let first = pendingSave.first, let last = pendingSave.last else { return }

        let track = Track(
            name: trackName.trimmingCharacters(in: .whitespaces),
            points: [CodableCoordinate(first), CodableCoordinate(last)],
            startPoint: CodableCoordinate(first),
            finishPoint: CodableCoordinate(last),
            isLoop: false,
            isRouted: true
        )
        store.add(track)
        showNameSheet = false
        Haptics.success()
        dismiss()
    }
}
