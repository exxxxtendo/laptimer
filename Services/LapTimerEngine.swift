import Foundation
import CoreLocation

final class LapTimerEngine: ObservableObject {
    @Published var isTiming: Bool = false
    @Published var currentLapTime: TimeInterval = 0
    @Published var lastLapTime: TimeInterval?
    @Published var bestLapTime: TimeInterval?
    @Published var delta: TimeInterval = 0 
    @Published var lapCount: Int = 0
    @Published var laps: [Lap] = []
    
    private(set) var track: Track?
    private var lapStart: Date?
    private var timer: Timer?
    
    var startZoneRadius: Double = 40
    var finishZoneRadius: Double = 40
    private var isInStartZone = false
    private var isInFinishZone = false
    private var hasLeftStartZone = false

    // ДОБАВИЛИ initialBest
    func start(with track: Track?, initialBest: TimeInterval? = nil) {
        self.track = track
        laps = []
        lapCount = 0
        lastLapTime = nil
        bestLapTime = initialBest // <--- Устанавливаем рекорд трассы при старте
        delta = 0
        lapStart = nil
        currentLapTime = 0
        isInStartZone = false
        isInFinishZone = false
        hasLeftStartZone = false
        isTiming = false 
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isTiming = false
    }

    func manualStart() {
        lapStart = Date()
        currentLapTime = 0
        delta = 0
        isTiming = true
        hasLeftStartZone = true
        startTicker()
    }

    private func startTicker() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.lapStart else { return }
            self.currentLapTime = Date().timeIntervalSince(start)
            
            // Считаем дельту только если есть best
            if let best = self.bestLapTime {
                self.delta = self.currentLapTime - best
            }
        }
    }

    func process(_ location: CLLocation) {
        guard let track = track else {
            if !isTiming && location.speed > 1.0 {
                manualStart()
            }
            return
        }
        
        let startLocation = track.startPoint.clLocation
        let finishLocation = track.points.last?.clLocation ?? startLocation
        
        let insideStart = location.distance(from: startLocation) < startZoneRadius
        let insideFinish = location.distance(from: finishLocation) < finishZoneRadius
        
        if insideStart && !isInStartZone && !isTiming {
            lapStart = Date()
            currentLapTime = 0
            delta = 0
            isTiming = true
            hasLeftStartZone = false
            startTicker()
        }
        
        if isTiming && !insideStart {
            hasLeftStartZone = true
        }
        
        if insideFinish && !isInFinishZone && isTiming && hasLeftStartZone {
            if let start = lapStart {
                let t = Date().timeIntervalSince(start)
                if t >= 3 {
                    let lap = Lap(time: t, date: Date())
                    laps.append(lap)
                    lapCount += 1
                    lastLapTime = t
                    if bestLapTime == nil || t < bestLapTime! { bestLapTime = t }
                }
            }
            isTiming = false
            lapStart = nil
            timer?.invalidate()
            timer = nil
        }
        
        isInStartZone = insideStart
        isInFinishZone = insideFinish
    }
}
