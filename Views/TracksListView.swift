import SwiftUI

struct TracksListView: View {
    @EnvironmentObject var store: TrackStore
    @State private var showRecorder = false
    @State private var showManualRecorder = false // <--- Новая переменная для ручной трассы
    @State private var activeTrack: Track?

    var body: some View {
        List {
            // ПЕРВАЯ СЕКЦИЯ (список трасс - оставляем как есть)
            Section {
                ForEach(store.tracks) { track in
                    Button { activeTrack = track } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.name).font(.headline)
                            Text("\(String(format: "%.0f", track.lengthMeters)) м · \(track.points.count) точек")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { idx in idx.map { store.tracks[$0] }.forEach(store.delete) }
            } header: { Text("Трассы") }

            // ВТОРАЯ СЕКЦИЯ (кнопки создания - вот тут изменения)
            Section {
                Button { showRecorder = true } label: {
                    Label("Записать новую трассу", systemImage: "record.circle")
                }
                
                Button { showManualRecorder = true } label: {
                    Label("Нарисовать трассу вручную", systemImage: "hand.draw")
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Кольцо")
        .sheet(isPresented: $showRecorder) {
            RecordTrackView().environmentObject(store)
        }
        .sheet(isPresented: $showManualRecorder) {
            ManualTrackView().environmentObject(store)
        }
        .fullScreenCover(item: $activeTrack) { track in
            SessionView(track: track)
        }
    }
}
