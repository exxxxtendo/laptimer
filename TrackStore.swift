import Foundation

/// Хранилище трасс (tracks.json) плюс «последняя открытая трасса».
final class TrackStore: ObservableObject {
    @Published private(set) var tracks: [Track] = []

    /// Последняя трасса, на которой ехали — для быстрого старта с главного экрана.
    @Published private(set) var lastTrackID: UUID?

    private let fileName = "tracks.json"
    private let lastTrackKey = "lastTrackID"

    private var url: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(fileName)
    }

    init() {
        load()
        if let raw = UserDefaults.standard.string(forKey: lastTrackKey) {
            lastTrackID = UUID(uuidString: raw)
        }
    }

    var lastTrack: Track? {
        guard let lastTrackID = lastTrackID else { return nil }
        return tracks.first { $0.id == lastTrackID }
    }

    func track(withID id: UUID) -> Track? {
        tracks.first { $0.id == id }
    }

    func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Track].self, from: data)
        else { return }
        tracks = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func add(_ track: Track) {
        tracks.insert(track, at: 0)
        save()
    }

    func update(_ track: Track) {
        guard let index = tracks.firstIndex(where: { $0.id == track.id }) else {
            add(track)
            return
        }
        tracks[index] = track
        save()
    }

    func rename(_ track: Track, to name: String) {
        var copy = track
        copy.name = name
        update(copy)
    }

    func delete(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
        if lastTrackID == track.id {
            lastTrackID = tracks.first?.id
        }
        save()
    }

    func markUsed(_ track: Track) {
        lastTrackID = track.id
        UserDefaults.standard.set(track.id.uuidString, forKey: lastTrackKey)
    }
}
