import Foundation
import CoreLocation

struct CodableCoordinate: Codable, Equatable, Hashable {
    var lat: Double
    var lon: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: lat, longitude: lon)
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        lat = coordinate.latitude
        lon = coordinate.longitude
    }

    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
}

struct Track: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var points: [CodableCoordinate]
    var startPoint: CodableCoordinate
    var finishPoint: CodableCoordinate
    var createdAt: Date
    var lengthMeters: Double
    /// Старт и финиш находятся в одном месте — считаем круги по одной линии.
    var isLoop: Bool
    /// Точек всего две: полноценная линия трека строится через маршрутизатор Apple.
    var isRouted: Bool

    init(id: UUID = UUID(),
         name: String,
         points: [CodableCoordinate],
         startPoint: CodableCoordinate? = nil,
         finishPoint: CodableCoordinate? = nil,
         createdAt: Date = Date(),
         lengthMeters: Double? = nil,
         isLoop: Bool? = nil,
         isRouted: Bool? = nil) {
        self.id = id
        self.name = name
        self.points = points
        let resolvedStart = startPoint ?? points.first ?? CodableCoordinate(lat: 0, lon: 0)
        let resolvedFinish = finishPoint ?? points.last ?? resolvedStart
        self.startPoint = resolvedStart
        self.finishPoint = resolvedFinish
        self.createdAt = createdAt

        let measured = lengthMeters ?? Geo.length(points)
        self.lengthMeters = measured.isFinite ? max(0, measured) : 0

        self.isRouted = isRouted ?? (points.count <= 2)
        if let isLoop = isLoop {
            self.isLoop = isLoop
        } else {
            self.isLoop = Geo.distance(resolvedStart.coordinate, resolvedFinish.coordinate) < 70
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Трасса"
        points = try container.decodeIfPresent([CodableCoordinate].self, forKey: .points) ?? []

        let storedStart = try container.decodeIfPresent(CodableCoordinate.self, forKey: .startPoint)
        let storedFinish = try container.decodeIfPresent(CodableCoordinate.self, forKey: .finishPoint)
        startPoint = storedStart ?? points.first ?? CodableCoordinate(lat: 0, lon: 0)
        finishPoint = storedFinish ?? points.last ?? startPoint
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()

        let storedLength = try container.decodeIfPresent(Double.self, forKey: .lengthMeters) ?? 0
        let measured = Geo.length(points)
        if storedLength > 1 {
            lengthMeters = storedLength
        } else {
            lengthMeters = measured
        }

        if let storedLoop = try container.decodeIfPresent(Bool.self, forKey: .isLoop) {
            isLoop = storedLoop
        } else {
            isLoop = Geo.distance(startPoint.coordinate, finishPoint.coordinate) < 70
        }

        isRouted = try container.decodeIfPresent(Bool.self, forKey: .isRouted) ?? (points.count <= 2)
    }

    /// Длина для интерфейса: если реальная длина неизвестна, показываем хотя бы прямую.
    var displayLength: Double {
        if lengthMeters > 1 { return lengthMeters }
        if points.count > 1 { return Geo.length(points) }
        return Geo.distance(startPoint.coordinate, finishPoint.coordinate)
    }

    var region: (center: CLLocationCoordinate2D, radius: Double) {
        Geo.boundingCircle(points: points.isEmpty ? [startPoint, finishPoint] : points)
    }
}
