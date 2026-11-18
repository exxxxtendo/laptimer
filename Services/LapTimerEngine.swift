import Foundation
import CoreLocation

enum SessionState: Equatable {
    /// Свободный режим: секундомер стоит.
    case idle
    /// Трасса: ждём пересечения стартовой линии.
    case armed
    /// Идёт отсчёт круга.
    case running
    /// Свободный режим: пауза.
    case paused

    var isCounting: Bool { self == .running }
}

private enum ZoneEvent {
    case enter
    case exit
}

/// Круглая зона с гистерезисом: чтобы «войти», нужно оказаться ближе `radius`,
/// чтобы «выйти» — дальше `radius * 1.6`. Это убирает дребезг на границе круга.
private struct ZoneGate {
    let center: CLLocationCoordinate2D
    let radius: Double
    var isInside: Bool

    init(center: CLLocationCoordinate2D, radius: Double, startsInside: Bool) {
        self.center = center
        self.radius = radius
        self.isInside = startsInside
    }

    mutating func update(distance: Double) -> ZoneEvent? {
        if isInside {
            if distance > radius * 1.6 {
                isInside = false
                return .exit
            }
            return nil
        }

        if distance < radius {
            isInside = true
            return .enter
        }
        return nil
    }
}

/// Движок заезда: либо круги по трассе, либо свободный секундомер.
///
/// Ключевые отличия от прежней версии:
/// - круг закрывается по пересечению линии старта, а не «вошёл в круг»;
/// - после финиша круг начинается сразу, без «мёртвой зоны»;
/// - если заезд начат, стоя на линии, первый круг не засчитывается мгновенно;
/// - направление движения проверяется, чтобы разворот у линии не давал фальшивый круг;
/// - прогноз времени круга по пройденной дистанции вместо невнятной дельты.
final class LapTimerEngine: ObservableObject {
    // MARK: - Состояние

    @Published private(set) var state: SessionState = .idle
    @Published private(set) var currentLapTime: TimeInterval = 0
    @Published private(set) var lastLapTime: TimeInterval?
    @Published private(set) var bestLapTime: TimeInterval?
    @Published private(set) var predictedLapTime: TimeInterval?
    @Published private(set) var delta: TimeInterval?
    @Published private(set) var laps: [Lap] = []
    @Published private(set) var speedKph: Double = 0
    @Published private(set) var topSpeedKph: Double = 0
    @Published private(set) var distanceMeters: Double = 0
    @Published private(set) var progress: Double = 0

    // MARK: - Настройки

    /// Минимальное время круга: защита от двойного срабатывания на линии.
    let minimumLapTime: TimeInterval = 6

    private(set) var track: Track?
    /// Рекорд трассы (для дельты).
    private(set) var referenceBest: TimeInterval?
    private(set) var startedAt: Date?

    var isFreeMode: Bool { track == nil }

    var lapCount: Int { laps.count }

    var hasData: Bool { !laps.isEmpty }

    // MARK: - Приватное

    private var lapStart: Date?
    private var elapsedBase: TimeInterval = 0
    private var timer: Timer?
    private var lastLocation: CLLocation?

    private var startGate: ZoneGate?
    private var finishGate: ZoneGate?
    private var startHeading: Double?
    private var isLoop = true

    private var path: [CLLocationCoordinate2D] = []
    private var cumulative: [Double] = []
    private var pathLength: Double = 1
    private var progressIndex = 0
    private var smoothedProgress: Double = 0
    private var hasProgressThisLap = false

    init(track: Track?) {
        self.track = track
        if let track = track {
            prepareTrack(track)
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Жизненный цикл

    /// Готовит заезд. Для трассы — «взводит» ожидание стартовой линии.
    func start(from location: CLLocation?, reference: TimeInterval?) {
        referenceBest = reference
        laps = []
        lastLapTime = nil
        bestLapTime = nil
        predictedLapTime = nil
        delta = nil
        currentLapTime = 0
        distanceMeters = 0
        topSpeedKph = 0
        speedKph = 0
        progress = 0
        smoothedProgress = 0
        hasProgressThisLap = false
        progressIndex = 0
        elapsedBase = 0
        lapStart = nil
        startedAt = Date()
        stopTicker()

        guard let track = track else {
            lastLocation = location
            state = .idle
            return
        }

        let radius = gateRadius
        startGate = ZoneGate(
            center: track.startPoint.coordinate,
            radius: radius,
            startsInside: location.map { Geo.distance($0.coordinate, track.startPoint.coordinate) < radius } ?? false
        )
        finishGate = ZoneGate(
            center: track.finishPoint.coordinate,
            radius: radius,
            startsInside: location.map { Geo.distance($0.coordinate, track.finishPoint.coordinate) < radius } ?? false
        )
        lastLocation = location
        state = .armed
    }

    /// Останавливает отсчёт, но не стирает результат.
    func stop() {
        commitElapsed()
        stopTicker()
        if state == .running {
            state = isFreeMode ? .paused : .armed
        }
    }

    func reset() {
        stopTicker()
        state = .idle
        laps = []
        lastLapTime = nil
        bestLapTime = nil
        predictedLapTime = nil
        delta = nil
        currentLapTime = 0
        elapsedBase = 0
        lapStart = nil
        distanceMeters = 0
        topSpeedKph = 0
        progress = 0
        smoothedProgress = 0
        hasProgressThisLap = false
        progressIndex = 0
        startedAt = Date()
    }

    // MARK: - Свободный режим

    func toggleFreeSession() {
        guard isFreeMode else { return }
        switch state {
        case .idle:
            reset()
            beginLap()
        case .running:
            pauseFree()
        case .paused:
            resumeFree()
        case .armed:
            break
        }
    }

    /// Отметить круг вручную (свободный режим).
    func markLap() {
        guard isFreeMode, state == .running else { return }
        let time = elapsed
        guard time >= 1 else { return }
        appendLap(time: time)
        elapsedBase = 0
        lapStart = Date()
        currentLapTime = 0
    }

    private func pauseFree() {
        commitElapsed()
        stopTicker()
        state = .paused
    }

    private func resumeFree() {
        lapStart = Date()
        state = .running
        startTicker()
    }

    // MARK: - GPS

    func process(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 50 else { return }
        guard abs(location.timestamp.timeIntervalSinceNow) < 8 else { return }

        let kph = (location.speed >= 0 && location.speed < 200) ? location.speed * 3.6 : 0
        speedKph = kph
        if kph > topSpeedKph { topSpeedKph = kph }

        let previous = lastLocation
        if let previous = previous, location.speed >= 0.5 {
            let step = location.distance(from: previous)
            if step > 0.5 && step < 150 {
                distanceMeters += step
            }
        }

        if track != nil {
            updateProgress(location)
            checkGates(location: location, previous: previous ?? location)
        }

        lastLocation = location
    }

    // MARK: - Круги

    private var elapsed: TimeInterval {
        guard let lapStart = lapStart else { return elapsedBase }
        return elapsedBase + Date().timeIntervalSince(lapStart)
    }

    private func beginLap() {
        elapsedBase = 0
        lapStart = Date()
        currentLapTime = 0
        predictedLapTime = nil
        delta = nil
        progress = 0
        smoothedProgress = 0
        hasProgressThisLap = false
        progressIndex = 0
        state = .running
        startTicker()
    }

    private func appendLap(time: TimeInterval) {
        let lap = Lap(index: laps.count + 1, time: time, date: Date())
        if time < (bestLapTime ?? .greatestFiniteMagnitude) {
            bestLapTime = time
        }
        laps.append(lap)
        lastLapTime = time
    }

    private func commitElapsed() {
        guard let lapStart = lapStart else { return }
        elapsedBase += Date().timeIntervalSince(lapStart)
        self.lapStart = nil
        currentLapTime = elapsedBase
    }

    // MARK: - Ворота

    private var gateRadius: Double {
        guard let track = track else { return 45 }
        // Для коротких трасс уменьшаем радиус, чтобы зоны старта и финиша не слипались.
        if isLoop { return 40 }
        let distanceBetweenGates = Geo.distance(track.startPoint.coordinate, track.finishPoint.coordinate)
        return max(20, min(45, distanceBetweenGates / 4))
    }

    private func checkGates(location: CLLocation, previous: CLLocation) {
        let segmentStart = previous.coordinate
        let segmentEnd = location.coordinate

        var startEvent: ZoneEvent?
        if var gate = startGate {
            let distance = min(
                Geo.distanceToSegment(gate.center, segmentStart, segmentEnd),
                Geo.distance(segmentEnd, gate.center)
            )
            startEvent = gate.update(distance: distance)
            startGate = gate
        }

        var finishEvent: ZoneEvent?
        if !isLoop, var gate = finishGate {
            let distance = min(
                Geo.distanceToSegment(gate.center, segmentStart, segmentEnd),
                Geo.distance(segmentEnd, gate.center)
            )
            finishEvent = gate.update(distance: distance)
            finishGate = gate
        }

        switch state {
        case .armed:
            if startEvent == .enter, isHeadingCorrect(location) {
                beginLap()
                Haptics.medium()
            }

        case .running:
            if isLoop {
                if startEvent == .enter, currentLapTime >= minimumLapTime {
                    let time = elapsed
                    appendLap(time: time)
                    Haptics.heavy()
                    beginLap()
                }
            } else {
                if finishEvent == .enter, currentLapTime >= minimumLapTime {
                    let time = elapsed
                    appendLap(time: time)
                    Haptics.heavy()
                    state = .armed
                    commitElapsed()
                    stopTicker()
                }
            }

        case .idle, .paused:
            break
        }
    }

    /// Проверяем, что водитель едет вдоль трассы, а не разворачивается у линии.
    private func isHeadingCorrect(_ location: CLLocation) -> Bool {
        guard let expected = startHeading,
              location.course >= 0,
              location.speed > 1.5
        else { return true }
        return Geo.angleDifference(location.course, expected) < 110
    }

    private func prepareTrack(_ track: Track) {
        isLoop = track.isLoop

        path = track.points.count > 2 ? track.points.map { $0.coordinate } : [track.startPoint.coordinate, track.finishPoint.coordinate]

        cumulative = [0]
        var total: Double = 0
        if path.count > 1 {
            for index in 1..<path.count {
                total += Geo.distance(path[index - 1], path[index])
                cumulative.append(total)
            }
        }
        pathLength = max(total, 1)

        startHeading = firstBearing(from: track)
    }

    private func firstBearing(from track: Track) -> Double? {
        let start = track.startPoint.coordinate
        guard track.points.count > 1 else { return nil }
        for point in track.points.dropFirst() {
            if Geo.distance(start, point.coordinate) >= 25 {
                return Geo.bearing(from: start, to: point.coordinate)
            }
        }
        if let last = track.points.last, Geo.distance(start, last.coordinate) > 3 {
            return Geo.bearing(from: start, to: last.coordinate)
        }
        return nil
    }

    // MARK: - Прогресс по дистанции

    private func updateProgress(_ location: CLLocation) {
        guard state == .running, path.count > 1, cumulative.count == path.count else { return }

        let point = location.coordinate
        let windowStart = max(0, progressIndex - 4)
        let windowEnd = min(path.count - 2, progressIndex + 60)
        guard windowEnd >= windowStart else { return }

        var bestDistance = Double.greatestFiniteMagnitude
        var bestIndex = progressIndex
        var bestParameter: Double = 0

        for index in windowStart...windowEnd {
            let result = Geo.distanceAndParameterToSegment(point, path[index], path[index + 1])
            if result.distance < bestDistance {
                bestDistance = result.distance
                bestIndex = index
                bestParameter = result.parameter
            }
        }

        // Слишком далеко от линии трека — не верим такому прогрессу.
        guard bestDistance < 70 else { return }

        progressIndex = bestIndex
        let segmentLength = cumulative[bestIndex + 1] - cumulative[bestIndex]
        let travelled = cumulative[bestIndex] + segmentLength * bestParameter
        let rawProgress = min(1, max(0, travelled / pathLength))

        if !hasProgressThisLap {
            smoothedProgress = rawProgress
            hasProgressThisLap = true
        } else {
            smoothedProgress = smoothedProgress * 0.75 + rawProgress * 0.25
        }
        progress = smoothedProgress
    }

    private func updatePrediction() {
        guard !isFreeMode else {
            predictedLapTime = nil
            delta = nil
            return
        }

        guard currentLapTime > 1, hasProgressThisLap, smoothedProgress > 0.2 else {
            predictedLapTime = nil
            return
        }

        let predicted = currentLapTime / smoothedProgress
        predictedLapTime = predicted
        if let reference = referenceBest {
            delta = predicted - reference
        } else {
            delta = nil
        }
    }

    // MARK: - Таймер

    private func startTicker() {
        stopTicker()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTicker() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        currentLapTime = elapsed
        updatePrediction()
    }
}
