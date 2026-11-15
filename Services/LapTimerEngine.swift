import Foundation
import CoreLocation

final class LapTimerEngine: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var currentLapTime: TimeInterval = 0
    @Published var lastLapTime: TimeInterval?
    @Published var bestLapTime: TimeInterval?
    @Published var delta: TimeInterval = 0 // НОВОЕ: разница с лучшим временем
    @Published var lapCount: Int = 0
    @Published var laps: [Lap] = []
    
    private(set) var track: Track?
    private var lapStart: Date?
    private var timer: Timer?
    
    // Настройки срабатывания зон
    var startZoneRadius: Double = 30 // 30 метров от точки старта
    var finishZoneRadius: Double = 30 // 30 метров от точки финиша
    var minSpeedForLap: Double = 2.0 // Минимальная скорость (м/с)
    
    private var isInStartZone = false
    private var isInFinishZone = false

    func start(with track: Track) {
        self.track = track
        laps = []
        lapCount = 0
        lastLapTime = nil
        bestLapTime = nil
        delta = 0 // Сбрасываем delta
        lapStart = nil
        currentLapTime = 0
        isInStartZone = false
        isInFinishZone = false
        isRunning = true
        startTicker()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func startTicker() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.lapStart else { return }
            self.currentLapTime = Date().timeIntervalSince(start)
            
            // ЖИВОЙ РАСЧЕТ DELTA
            if let best = self.bestLapTime {
                self.delta = self.currentLapTime - best
            } else {
                self.delta = 0
            }
        }
    }

    func process(_ location: CLLocation) {
        guard isRunning, let track = track else { return }
        
        // Берем координаты старта и финиша
        let startLocation = track.startPoint.clLocation
        let finishLocation = track.points.last?.clLocation ?? startLocation
        
        let distanceToStart = location.distance(from: startLocation)
        let distanceToFinish = location.distance(from: finishLocation)
        
        let insideStart = distanceToStart < startZoneRadius
        let insideFinish = distanceToFinish < finishZoneRadius
        let fastEnough = location.speed > minSpeedForLap
        
        // 1. ЛОГИКА СТАРТА
        if insideStart && !isInStartZone && fastEnough {
            if lapStart == nil {
                lapStart = Date()
                currentLapTime = 0
                delta = 0
            }
        }
        
        // 2. ЛОГИКА ФИНИША
        if insideFinish && !isInFinishZone && fastEnough {
            if let start = lapStart {
                let t = Date().timeIntervalSince(start)
                
                // Защита от случайного срабатывания (минимум 5 секунд)
                if t >= 5 {
                    let lap = Lap(time: t, date: Date())
                    laps.append(lap)
                    lapCount += 1
                    lastLapTime = t
                    
                    if bestLapTime == nil || t < bestLapTime! {
                        bestLapTime = t
                    }
                    
                    // Останавливаем таймер, так как доехали до финиша
                    stop()
                }
            }
        }
        
        isInStartZone = insideStart
        isInFinishZone = insideFinish
    }
}
