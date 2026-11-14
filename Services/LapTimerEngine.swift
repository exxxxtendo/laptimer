import Foundation
import CoreLocation

final class LapTimerEngine: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var currentLapTime: TimeInterval = 0
    @Published var lastLapTime: TimeInterval?
    @Published var bestLapTime: TimeInterval?
    @Published var lapCount: Int = 0
    @Published var laps: [Lap] = []
    @Published var isInStartZone: Bool = false

    private(set) var track: Track?
    private var lapStart: Date?
    private var timer: Timer?
    var startZoneRadius: Double = 25
    var minLapTime: TimeInterval = 15
    var minSpeedForLap: Double = 5

    func start(with track: Track) {
        self.track = track
        laps = []; lapCount = 0; lastLapTime = nil; bestLapTime = nil
        lapStart = nil; currentLapTime = 0; isInStartZone = false
        isRunning = true
        startTicker()
    }

    func stop() {
        timer?.invalidate(); timer = nil
        isRunning = false
    }

    private func startTicker() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let start = self.lapStart else { return }
            self.currentLapTime = Date().timeIntervalSince(start)
        }
    }

    func process(_ location: CLLocation) {
        guard isRunning, let track else { return }
        let d = location.distance(from: track.startPoint.clLocation)
        let inside = d < startZoneRadius
        let fastEnough = location.speed > minSpeedForLap
        if inside && !isInStartZone && fastEnough {
            if let start = lapStart {
                let t = Date().timeIntervalSince(start)
                if t >= minLapTime {
                    let lap = Lap(time: t, date: Date())
                    laps.append(lap); lapCount += 1; lastLapTime = t
                    if bestLapTime == nil || t < bestLapTime! { bestLapTime = t }
                    lapStart = Date(); currentLapTime = 0
                }
            } else {
                lapStart = Date(); currentLapTime = 0
            }
        }
        isInStartZone = inside
    }
}
