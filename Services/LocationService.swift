import Foundation
import CoreLocation

final class LocationService: NSObject, ObservableObject {
    @Published var lastLocation: CLLocation?
    @Published var speedKph: Double = 0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdating: Bool = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = false
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func requestPermission() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestAlwaysAuthorization()
        }
    }

    func start() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
        isUpdating = true
    }

    func stop() {
        manager.stopUpdatingLocation()
        isUpdating = false
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { self.authorizationStatus = manager.authorizationStatus }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last, loc.horizontalAccuracy >= 0, loc.horizontalAccuracy < 30 else { return }
        let kph = max(0, loc.speed) * 3.6
        DispatchQueue.main.async {
            self.lastLocation = loc
            self.speedKph = kph
        }
    }
}
