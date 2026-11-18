import Foundation

/// Результат одного заезда — сохраняется в историю.
struct SessionResult: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var trackID: UUID?
    var trackName: String
    var date: Date = Date()
    var laps: [Lap] = []

    var best: TimeInterval? {
        laps.best?.time
    }

    var average: TimeInterval? {
        laps.average
    }

    var isFreeDrive: Bool {
        trackID == nil
    }
}

/// Личный рекорд по конкретной трассе.
struct TrackRecord: Identifiable, Codable, Equatable {
    var trackID: UUID
    var trackName: String
    var bestLap: TimeInterval
    var bestLapDate: Date?
    var lastLap: TimeInterval?
    var lastSessionDate: Date?
    var lapCount: Int
    var sessionCount: Int
    var totalLapTime: TimeInterval

    var id: UUID { trackID }

    var averageLap: TimeInterval? {
        guard lapCount > 0, totalLapTime > 0 else { return nil }
        return totalLapTime / Double(lapCount)
    }
}
