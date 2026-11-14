import CoreLocation

struct CodableCoordinate: Codable, Equatable, Hashable {
    var lat: Double
    var lon: Double
    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lon) }
    var clLocation: CLLocation { .init(latitude: lat, longitude: lon) }
    init(_ c: CLLocationCoordinate2D) { lat = c.latitude; lon = c.longitude }
    init(lat: Double, lon: Double) { self.lat = lat; self.lon = lon }
}

struct Track: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var points: [CodableCoordinate]
    var startPoint: CodableCoordinate
    var createdAt: Date = Date()
    var lengthMeters: Double
}
