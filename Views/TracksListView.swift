import SwiftUI

struct TracksListView: View {
    @EnvironmentObject var store: TrackStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showRecorder = false
    @State private var showSettings = false
    @State private var showManualDrawer = false // Для ручного добавления
    @State private var activeTrack: Track?

    var body: some View {
        List {
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

            Section {
                Button { showRecorder = true } label: {
                    Label("Записать новую трассу", systemImage: "record.circle")
                }
                
                // Возвращаем кнопку ручного добавления!
                Button { showManualDrawer = true } label: {
                    Label("Нарисовать на карте", systemImage: "pencil.tip")
                }
            }
        }
        .navigationTitle("Кольцо")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .sheet(isPresented: $showRecorder) {
            RecordTrackView().environmentObject(store)
        }
        .sheet(isPresented: $showManualDrawer) {
            ManualTrackView().environmentObject(store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(themeManager)
        }
        .fullScreenCover(item: $activeTrack) { track in
            SessionView(track: track)
        }
    }
}
