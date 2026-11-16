import SwiftUI

struct TracksListView: View {
    @EnvironmentObject var store: TrackStore
    @Environment(\.dismiss) private var dismiss
    @State private var showRecorder = false
    @State private var showManualRecorder = false
    @State private var activeTrack: Track?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    Section {
                        ForEach(store.tracks) { track in
                            Button { activeTrack = track; dismiss() } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(track.name).font(.headline).foregroundColor(.white)
                                    Text("\(String(format: "%.0f", track.lengthMeters)) м · \(track.points.count) точек")
                                        .font(.caption).foregroundColor(.gray)
                                }
                            }
                            .listRowBackground(Color(white: 0.1))
                        }
                        .onDelete { idx in idx.map { store.tracks[$0] }.forEach(store.delete) }
                    } header: { Text("Трассы").foregroundColor(.gray) }

                    Section {
                        Button { showRecorder = true } label: {
                            Label("Записать новую трассу", systemImage: "record.circle")
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color(white: 0.1))
                        
                        Button { showManualRecorder = true } label: {
                            Label("Добавить вручную", systemImage: "hand.draw")
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color(white: 0.1))
                    }
                }
            }
            .navigationTitle("Гараж")
            .toolbar {
                Button("Закрыть") { dismiss() }.foregroundColor(.white)
            }
        }
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
