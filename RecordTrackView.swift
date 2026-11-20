import SwiftUI
import CoreLocation

/// Запись трассы по GPS: рисует пройденный путь и сохраняет трек.
struct RecordTrackView: View {
    @EnvironmentObject private var store: TrackStore
    @EnvironmentObject private var location: LocationService
    @Environment(\.dismiss) private var dismiss

    @State private var path: [CLLocationCoordinate2D] = []
    @State private var length: Double = 0
    @State private var isRecording = false
    @State private var showNameSheet = false
    @State private var trackName = ""

    var body: some View {
        ZStack {
            RecordingMapView(path: path, followsUser: true)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomPanel
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            location.start()
        }
        .onDisappear {
            location.stop()
        }
        .onChange(of: location.lastLocation) { newLocation in
            guard isRecording, let location = newLocation else { return }
            append(location)
        }
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
            HStack(spacing: 24) {
                LabeledValue(label: "дистанция", value: Fmt.distance(length))
                LabeledValue(label: "точек", value: "\(path.count)")
                LabeledValue(label: "статус", value: statusText, tint: isRecording ? Theme.accent : Theme.textSecondary, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(GlassBackground(cornerRadius: 20))

            if isRecording && !hasEnoughPoints {
                Text("Проедьте хотя бы 50 метров, чтобы сохранить трассу")
                    .font(Theme.body(12))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: toggleRecording) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(isRecording ? Color.white : Theme.accent)
                        .frame(width: 10, height: 10)
                        .opacity(isRecording ? 1 : 0.9)
                    Text(isRecording ? "СТОП" : "ЗАПИСЬ")
                        .font(Theme.number(16, weight: .heavy))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .buttonStyle(PrimaryButtonStyle(color: isRecording ? Theme.negative : Theme.accent))
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.bottom, 20)
    }

    private var statusText: String {
        isRecording ? "идёт запись" : "готов"
    }

    private var hasEnoughPoints: Bool {
        guard let first = path.first else { return false }
        let firstLocation = CLLocation(latitude: first.latitude, longitude: first.longitude)
        guard let last = path.last else { return false }
        let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
        return path.count > 5 && firstLocation.distance(from: lastLocation) < 120 && length > 50
    }

    // MARK: - Запись

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        path = []
        length = 0
        isRecording = true
        location.start()
        Haptics.medium()
    }

    private func stopRecording() {
        isRecording = false
        Haptics.success()
        trackName = defaultName
        showNameSheet = true
    }

    private var defaultName: String {
        "Трасса \(store.tracks.count + 1)"
    }

    private func append(_ location: CLLocation) {
        // Отбрасываем неточные точки.
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 30 else { return }

        if let last = path.last {
            let lastLocation = CLLocation(latitude: last.latitude, longitude: last.longitude)
            let distance = lastLocation.distance(from: location)

            // Скачок больше 100 метров — GPS-глюк, пропускаем.
            if distance > 100 { return }
            // Меньше 2 метров — не накопили достаточное смещение.
            if distance < 2 { return }

            length += distance
        }

        path.append(location.coordinate)
    }

    // MARK: - Сохранение

    private var nameSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Название трассы", text: $trackName)
                        .font(Theme.body(15, weight: .medium))
                } header: {
                    Text("Проверьте трассу на карте и дайте ей название")
                } footer: {
                    Text("Старт и финиш — в точке начала записи.")
                }

                Section {
                    HStack {
                        Text("Дистанция")
                        Spacer()
                        Text(Fmt.distance(length))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Точек трека")
                        Spacer()
                        Text("\(path.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Сохранить")
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { showNameSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .disabled(trackName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    private func save() {
        guard path.count > 5 else {
            showNameSheet = false
            dismiss()
            return
        }

        let track = Track(
            name: trackName.trimmingCharacters(in: .whitespaces),
            points: path.map { CodableCoordinate($0) },
            startPoint: CodableCoordinate(path[0]),
            lengthMeters: length
        )
        store.add(track)
        showNameSheet = false
        Haptics.success()
        dismiss()
    }
}
