import Foundation
import CoreLocation
import MapKit

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
    /// Точки, по которым рисуется линия трассы.
    /// Для «маршрутных» трасс здесь лежит полная геометрия маршрута Apple,
    /// а не только старт и финиш — поэтому превью совпадает с заездом.
    var points: [CodableCoordinate]
    var startPoint: CodableCoordinate
    var finishPoint: CodableCoordinate
    var createdAt: Date
    var lengthMeters: Double
    /// Старт и финиш в одном месте — считаем круги по одной линии.
    var isLoop: Bool
    /// Трасса была построена через маршрутизатор (две исходные точки).
    /// Нужен, чтобы понять: `points` — это геометрия маршрута или нет.
    var isRouted: Bool
    /// Геометрия маршрута уже загружена в `points`.
    var hasRouteGeometry: Bool

    init(id: UUID = UUID(),
         name: String,
         points: [CodableCoordinate],
         startPoint: CodableCoordinate? = nil,
         finishPoint: CodableCoordinate? = nil,
         createdAt: Date = Date(),
         lengthMeters: Double? = nil,
         isLoop: Bool? = nil,
         isRouted: Bool? = nil,
         hasRouteGeometry: Bool? = nil) {
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
        self.hasRouteGeometry = hasRouteGeometry ?? (points.count > 2)

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
        if storedLength > 1 {
            lengthMeters = storedLength
        } else {
            lengthMeters = Geo.length(points)
        }

        if let storedLoop = try container.decodeIfPresent(Bool.self, forKey: .isLoop) {
            isLoop = storedLoop
        } else {
            isLoop = Geo.distance(startPoint.coordinate, finishPoint.coordinate) < 70
        }

        isRouted = try container.decodeIfPresent(Bool.self, forKey: .isRouted) ?? (points.count <= 2)
        hasRouteGeometry = try container.decodeIfPresent(Bool.self, forKey: .hasRouteGeometry) ?? (points.count > 2)
    }

    /// Нужно ли доставить геометрию маршрута (старые трассы, созданные без неё).
    var needsRouteGeometry: Bool {
        guard isRouted, !hasRouteGeometry else { return false }
        return Geo.distance(startPoint.coordinate, finishPoint.coordinate) > 30
    }

    /// Длина для интерфейса.
    var displayLength: Double {
        if lengthMeters > 1 { return lengthMeters }
        if points.count > 1 { return Geo.length(points) }
        return Geo.distance(startPoint.coordinate, finishPoint.coordinate)
    }

    var region: (center: CLLocationCoordinate2D, radius: Double) {
        Geo.boundingCircle(points: points.isEmpty ? [startPoint, finishPoint] : points)
    }
}

// MARK: - Загрузка геометрии маршрута

enum RouteGeometryLoader {
    /// Запрашивает у Apple полную геометрию маршрута между стартом и финишем
    /// и возвращает трассу с заполненными `points`.
    static func load(for track: Track, completion: @escaping (Track?) -> Void) {
        guard track.needsRouteGeometry else {
            completion(nil)
            return
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: track.startPoint.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: track.finishPoint.coordinate))
        request.transportType = .automobile

        MKDirections(request: request).calculate { response, _ in
            DispatchQueue.main.async {
                guard let route = response?.routes.first else {
                    completion(nil)
                    return
                }

                var updated = track
                updated.points = route.polyline.coordinates.map { CodableCoordinate($0) }
                updated.hasRouteGeometry = true
                updated.lengthMeters = route.distance
                completion(updated)
            }
        }
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var result: [CLLocationCoordinate2D] = []
        result.reserveCapacity(pointCount)
        let points = self.points()
        for index in 0..<pointCount {
            result.append(points[index].coordinate)
        }
        return result
    }
}
