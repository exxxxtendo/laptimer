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

    func start(with track: Track?) {
        self.track = track
        laps = []
        lapCount = 0
        lastLapTime = nil
        bestLapTime = nil
        delta = 0
        lapStart = nil
        currentLapTime = 0
        isInStartZone = false
        isInFinishZone = false
        hasLeftStartZone = false
        isTiming = false
        
        // Если трасса не выбрана, запускаем таймер сразу (Free Drive)
        if track == nil {
            manualStart()
        }
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
            
            if let best = self.bestLapTime {
                self.delta = self.currentLapTime - best
            }
        }
    }

    func process(_ location: CLLocation) {
        // Если трассы нет, просто игнорируем логику финиша/старта
        guard let track = track else { return }
        
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
