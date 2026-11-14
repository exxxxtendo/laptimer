import Foundation

struct Lap: Identifiable, Codable, Equatable {
    var id = UUID()
    var time: TimeInterval
    var date: Date
}
