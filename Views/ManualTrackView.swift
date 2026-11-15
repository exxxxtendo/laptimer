import SwiftUI
import CoreLocation
import MapKit

struct ManualTrackView: View {
    @EnvironmentObject var store: TrackStore
    @Environment(\.dismiss) private var dismiss

    @State private var path: [CLLocationCoordinate2D] = []
    @State private var showNameSheet = false
    @State private var trackName = ""

    var body: some View {
        ZStack {
            // Обратите внимание: здесь path без знака $
            ManualTrackMapView(path: path) { newCoord in
                if path.count < 2 {
                    path.append(newCoord)
                }
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
                    if path.isEmpty {
                        Text("Нажмите на карту, чтобы поставить точку СТАРТА")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.6), in: Capsule())
                    } else if path.count == 1 {
                        Text("Теперь нажмите на карту, чтобы поставить точку ФИНИША")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.6), in: Capsule())
                    } else {
                        Text("Маршрут построен по дорогам. Нажмите Сохранить.")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.6), in: Capsule())
                    }

                    HStack(spacing: 12) {
                        Button {
                            path.removeAll()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.title3.weight(.bold))
                                .frame(width: 56, height: 56)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(path.isEmpty)

                        Button {
                            trackName = "Трасса \(store.tracks.count + 1)"
                            showNameSheet = true
                        } label: {
                            Text("Сохранить")
                                .font(.title3.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(path.count == 2 ? Color.blue : Color.gray.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.white)
                        }
                        .disabled(path.count != 2)
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

    private func saveTrack() {
        guard let first = path.first, let last = path.last else { return }
        
        let track = Track(
            name: trackName.trimmingCharacters(in: .whitespaces),
            points: [CodableCoordinate(first), CodableCoordinate(last)],
            startPoint: CodableCoordinate(first),
            lengthMeters: 0
        )
        store.add(track)
        showNameSheet = false
        dismiss()
    }
}
