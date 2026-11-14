import SwiftUI
import CoreLocation

struct ManualTrackView: View {
    @EnvironmentObject var store: TrackStore
    @Environment(\.dismiss) private var dismiss

    @State private var path: [CLLocationCoordinate2D] = []
    @State private var showNameSheet = false
    @State private var trackName = ""

    var body: some View {
        ZStack {
            // Карта с функцией нажатия (тыкалка)
            ManualTrackMapView(path: path) { newCoord in
                path.append(newCoord)
            }
            .ignoresSafeArea()

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                VStack(spacing: 12) {
                    // Подсказка, если трасса еще пустая
                    if path.isEmpty {
                        Text("Нажимайте на карту, чтобы ставить точки трассы")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.6), in: Capsule())
                    }

                    // Панель со статистикой
                    HStack(spacing: 24) {
                        stat("Дистанция", String(format: "%.0f м", calculateLength()))
                        stat("Точек", "\(path.count)")
                    }
                    .padding(.vertical, 12).padding(.horizontal, 20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    // Кнопки управления
                    HStack(spacing: 12) {
                        // Кнопка "Отменить последнюю точку"
                        Button {
                            if !path.isEmpty { path.removeLast() }
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.title3.weight(.bold))
                                .frame(width: 56, height: 56)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(path.isEmpty)

                        // Кнопка "Сохранить"
                        Button {
                            guard path.count >= 3 else { return }
                            trackName = "Трасса \(store.tracks.count + 1)"
                            showNameSheet = true
                        } label: {
                            Text("Сохранить")
                                .font(.title3.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(path.count >= 3 ? Color.blue : Color.gray.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                        }
                        .disabled(path.count < 3)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showNameSheet) {
            NavigationView {
                Form { TextField("Название трассы", text: $trackName) }
                    .navigationTitle("Сохранить")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Отмена") { showNameSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Сохранить") { saveTrack() }
                                .disabled(trackName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
            }
        }
    }

    // Функция подсчета дистанции
    private func calculateLength() -> Double {
        guard path.count > 1 else { return 0 }
        var dist: Double = 0
        for i in 0..<(path.count - 1) {
            let loc1 = CLLocation(latitude: path[i].latitude, longitude: path[i].longitude)
            let loc2 = CLLocation(latitude: path[i+1].latitude, longitude: path[i+1].longitude)
            dist += loc1.distance(from: loc2)
        }
        // Замыкаем круг (от последней точки к первой)
        if path.count >= 3 {
            let first = CLLocation(latitude: path[0].latitude, longitude: path[0].longitude)
            let last = CLLocation(latitude: path.last!.latitude, longitude: path.last!.longitude)
            dist += last.distance(from: first)
        }
        return dist
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.semibold)).monospacedDigit()
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }

    // Функция сохранения трассы в базу
    private func saveTrack() {
        guard let first = path.first else { return }
        let coords = path.map { CodableCoordinate($0) }
        
        let track = Track(
            name: trackName.trimmingCharacters(in: .whitespaces),
            points: coords,
            startPoint: CodableCoordinate(first),
            lengthMeters: calculateLength()
        )
        store.add(track)
        showNameSheet = false
        dismiss()
    }
}
