import Foundation
import CoreLocation
import MapKit

/// Геометрия в метрах. Для масштабов трека (сотни метров — километры)
/// плоская проекция вокруг средней широты даёт ошибку сильно меньше GPS-шума.
enum Geo {
    static let metersPerDegreeLatitude = 110_574.0

    static func metersPerDegreeLongitude(at latitude: Double) -> Double {
        let scaled = 111_320.0 * cos(latitude * .pi / 180.0)
        return max(scaled, 1.0)
    }

    static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let midLatitude = (a.latitude + b.latitude) / 2.0
        let dx = (b.longitude - a.longitude) * metersPerDegreeLongitude(at: midLatitude)
        let dy = (b.latitude - a.latitude) * metersPerDegreeLatitude
        return (dx * dx + dy * dy).squareRoot()
    }

    static func distance(_ a: CodableCoordinate, _ b: CodableCoordinate) -> Double {
        distance(a.coordinate, b.coordinate)
    }

    static func length(_ points: [CodableCoordinate]) -> Double {
        guard points.count > 1 else { return 0 }
        var total: Double = 0
        for index in 1..<points.count {
            total += distance(points[index - 1], points[index])
        }
        return total
    }

    /// Расстояние от точки `p` до отрезка `a–b` в метрах.
    static func distanceToSegment(_ p: CLLocationCoordinate2D,
                                  _ a: CLLocationCoordinate2D,
                                  _ b: CLLocationCoordinate2D) -> Double {
        distanceAndParameterToSegment(p, a, b).distance
    }

    /// Расстояние до отрезка и параметр проекции (0...1) вдоль него.
    static func distanceAndParameterToSegment(_ p: CLLocationCoordinate2D,
                                              _ a: CLLocationCoordinate2D,
                                              _ b: CLLocationCoordinate2D) -> (distance: Double, parameter: Double) {
        let kx = metersPerDegreeLongitude(at: p.latitude)
        let ky = metersPerDegreeLatitude

        let ax = (a.longitude - p.longitude) * kx
        let ay = (a.latitude - p.latitude) * ky
        let bx = (b.longitude - p.longitude) * kx
        let by = (b.latitude - p.latitude) * ky

        let dx = bx - ax
        let dy = by - ay
        let lengthSquared = dx * dx + dy * dy

        let parameter: Double
        if lengthSquared < 0.0001 {
            parameter = 0
        } else {
            parameter = min(1, max(0, -(ax * dx + ay * dy) / lengthSquared))
        }

        let cx = ax + parameter * dx
        let cy = ay + parameter * dy
        return ((cx * cx + cy * cy).squareRoot(), parameter)
    }

    static func bearing(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let lat1 = a.latitude * .pi / 180.0
        let lat2 = b.latitude * .pi / 180.0
        let deltaLon = (b.longitude - a.longitude) * .pi / 180.0
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        return atan2(y, x) * 180.0 / .pi
    }

    /// Наименьшая разница между двумя углами, 0...180.
    static func angleDifference(_ a: Double, _ b: Double) -> Double {
        var difference = a - b
        while difference > 180 { difference -= 360 }
        while difference < -180 { difference += 360 }
        return abs(difference)
    }

    /// Центр и радиус (в метрах) окружности, охватывающей все точки.
    static func boundingCircle(points: [CodableCoordinate]) -> (center: CLLocationCoordinate2D, radius: Double) {
        guard let first = points.first else {
            return (CLLocationCoordinate2D(latitude: 0, longitude: 0), 500)
        }
        var center = first.coordinate
        var radius: Double = 100
        for point in points {
            center.latitude += (point.lat - center.latitude) / 2.0
            center.longitude += (point.lon - center.longitude) / 2.0
            radius = max(radius, distance(center, point.coordinate))
        }
        return (center, radius)
    }

    /// Регион карты, охватывающий все точки трека.
    static func region(for points: [CodableCoordinate], paddingMeters: Double = 160) -> MKCoordinateRegion? {
        guard !points.isEmpty else { return nil }

        var minLat = points[0].lat
        var maxLat = points[0].lat
        var minLon = points[0].lon
        var maxLon = points[0].lon

        for point in points {
            minLat = min(minLat, point.lat)
            maxLat = max(maxLat, point.lat)
            minLon = min(minLon, point.lon)
            maxLon = max(maxLon, point.lon)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )

        let latSpan = (maxLat - minLat) * metersPerDegreeLatitude
        let lonSpan = (maxLon - minLon) * metersPerDegreeLongitude(at: center.latitude)

        let span = max(max(latSpan, lonSpan) + paddingMeters * 2, 400)
        let latitudeDelta = span / metersPerDegreeLatitude
        let longitudeDelta = span / metersPerDegreeLongitude(at: center.latitude)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }
}
