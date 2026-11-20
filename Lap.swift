import Foundation

/// Один пройденный круг.
struct Lap: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var index: Int
    var time: TimeInterval
    var date: Date = Date()

    init(id: UUID = UUID(), index: Int, time: TimeInterval, date: Date = Date()) {
        self.id = id
        self.index = index
        self.time = time
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        index = try container.decodeIfPresent(Int.self, forKey: .index) ?? 1
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time) ?? 0
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
    }
}

extension Array where Element == Lap {
    var best: Lap? {
        self.min { $0.time < $1.time }
    }

    var average: TimeInterval? {
        guard !isEmpty else { return nil }
        return reduce(0) { $0 + $1.time } / Double(count)
    }
}
