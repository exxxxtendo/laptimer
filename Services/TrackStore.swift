import Foundation

final class TrackStore: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("tracks.json")
    }

    init() { load() }
    func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Track].self, from: data)
        else { return }
        tracks = decoded
    }
    func save() {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        try? data.write(to: url, options: .atomic)
    }
    func add(_ track: Track) { tracks.append(track); save() }
    func delete(_ track: Track) { tracks.removeAll { $0.id == track.id }; save() }
}
