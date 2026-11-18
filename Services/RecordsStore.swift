import Foundation

/// Рекорды и история заездов.
///
/// Формат v2: `records_v2.json` = { records: [TrackRecord], history: [SessionResult] }.
/// Старый `records.json` ([имя трассы: время]) импортируется один раз при первом запуске,
/// чтобы личные рекорды не потерялись после обновления приложения.
final class RecordsStore: ObservableObject {
    @Published private(set) var records: [TrackRecord] = []
    @Published private(set) var history: [SessionResult] = []

    private let fileName = "records_v2.json"
    private let legacyFileName = "records.json"
    private let maxHistory = 100

    private var legacy: [String: TimeInterval] = [:]
    private var didMigrate = false

    private var url: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(fileName)
    }

    private var legacyURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(legacyFileName)
    }

    private struct FilePayload: Codable {
        var records: [TrackRecord]
        var history: [SessionResult]
    }

    init() {
        load()
        if records.isEmpty {
            loadLegacy()
        }
    }

    // MARK: - Чтение

    func record(for trackID: UUID) -> TrackRecord? {
        records.first { $0.trackID == trackID }
    }

    var totalLaps: Int {
        records.reduce(0) { $0 + $1.lapCount }
    }

    var trackCount: Int {
        records.count
    }

    func laps(for trackID: UUID) -> [Lap] {
        history
            .filter { $0.trackID == trackID }
            .flatMap { $0.laps }
            .sorted { $0.time < $1.time }
    }

    // MARK: - Запись

    func submit(_ session: SessionResult) {
        guard !session.laps.isEmpty, let best = session.best else { return }

        if let trackID = session.trackID {
            if let index = records.firstIndex(where: { $0.trackID == trackID }) {
                var record = records[index]
                record.trackName = session.trackName
                record.lapCount += session.laps.count
                record.sessionCount += 1
                record.totalLapTime += session.laps.reduce(0) { $0 + $1.time }
                record.lastLap = session.laps.last?.time
                record.lastSessionDate = session.date
                if best < record.bestLap {
                    record.bestLap = best
                    record.bestLapDate = session.date
                }
                records[index] = record
            } else {
                let record = TrackRecord(
                    trackID: trackID,
                    trackName: session.trackName,
                    bestLap: best,
                    bestLapDate: session.date,
                    lastLap: session.laps.last?.time,
                    lastSessionDate: session.date,
                    lapCount: session.laps.count,
                    sessionCount: 1,
                    totalLapTime: session.laps.reduce(0) { $0 + $1.time }
                )
                records.append(record)
            }
        }

        history.insert(session, at: 0)
        if history.count > maxHistory {
            history.removeLast(history.count - maxHistory)
        }
        save()
    }

    func removeRecord(for trackID: UUID) {
        records.removeAll { $0.trackID == trackID }
        history.removeAll { $0.trackID == trackID }
        save()
    }

    func clearAll() {
        records = []
        history = []
        save()
    }

    // MARK: - Персистентность

    func load() {
        guard let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(FilePayload.self, from: data)
        else { return }
        records = payload.records
        history = payload.history
    }

    func save() {
        let payload = FilePayload(records: records, history: history)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func loadLegacy() {
        guard let data = try? Data(contentsOf: legacyURL),
              let decoded = try? JSONDecoder().decode([String: TimeInterval].self, from: data)
        else { return }
        legacy = decoded
    }

    /// Привязывает старые рекорды (по имени трассы) к идентификаторам трасс.
    /// Вызывать после загрузки TrackStore.
    func migrateLegacy(tracks: [Track]) {
        guard !didMigrate, !legacy.isEmpty else { return }
        didMigrate = true

        var migrated = records
        for (name, time) in legacy {
            guard let track = tracks.first(where: { $0.name == name }) else { continue }
            if let index = migrated.firstIndex(where: { $0.trackID == track.id }) {
                var record = migrated[index]
                if time < record.bestLap {
                    record.bestLap = time
                }
                migrated[index] = record
            } else {
                migrated.append(
                    TrackRecord(
                        trackID: track.id,
                        trackName: track.name,
                        bestLap: time,
                        bestLapDate: nil,
                        lastLap: nil,
                        lastSessionDate: nil,
                        lapCount: 1,
                        sessionCount: 1,
                        totalLapTime: time
                    )
                )
            }
        }

        records = migrated
        legacy = [:]
        save()
        try? FileManager.default.removeItem(at: legacyURL)
    }
}
