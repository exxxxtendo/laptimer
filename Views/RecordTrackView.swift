import SwiftUI
import CoreLocation

struct RecordTrackView: View {
    @EnvironmentObject var store: TrackStore
    @EnvironmentObject var location: LocationService
    @Environment(\.dismiss) private var dismiss

    @State private var path: [CLLocationCoordinate2D] = []
    @State private var recording = false
    @State private var length: Double = 0
    @State private var showNameSheet = false
    @State private var trackName = ""

    var body: some View {
        ZStack {
            RecordingMapView(path: path).ignoresSafeArea()
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.title3.weight(.semibold))
                            .padding(12).background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }.padding()
                Spacer()
                VStack(spacing: 12) {
                    HStack(spacing: 24) {
                        stat("Дистанция", String(format: "%.0f м", length))
                        stat("Точек", "\(path.count)")
                    }
                    .padding(.vertical, 12).padding(.horizontal, 20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    Button {
                        recording ? stopRecording() : startRecording()
                    } label: {
                        Text(recording ? "Стоп" : "Запись")
                            .font(.title3.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(recording ? Color.red : Color.green,
                                        in: RoundedRectangle(cornerRadius: 16))
                            .foregroundColor(.white)
                    }
                }.padding()
            }
        }
               .onChange(of: location.lastLocation) { loc in
            guard recording, let loc else { return }
            
            // Защита от "телепортации" GPS: игнорируем, если скачок слишком большой (например, больше 100 метров за раз)
            if let last = path.last {
                let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
                let d = lastLoc.distance(from: loc)
                
                // Если GPS скаканул более чем на 100 метров, игнорируем эту точку (глюк)
                if d > 100 { return }
                
                if d >= 2 {
                    length += d
                    path.append(loc.coordinate)
                }
            } else {
                path.append(loc.coordinate)
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
                            Button("Сохранить") { save() }
                                .disabled(trackName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
            }
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.semibold)).monospacedDigit()
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }
    private func startRecording() { path = []; length = 0; recording = true; location.start() }
    private func stopRecording() {
        recording = false; location.stop()
        trackName = "Трасса \(store.tracks.count + 1)"; showNameSheet = true
    }
    private func save() {
        guard let first = path.first, path.count > 5 else { dismiss(); return }
        let coords = path.map { CodableCoordinate($0) }
        let track = Track(name: trackName.trimmingCharacters(in: .whitespaces),
                          points: coords, startPoint: CodableCoordinate(first), lengthMeters: length)
        store.add(track); showNameSheet = false; dismiss()
    }
}
