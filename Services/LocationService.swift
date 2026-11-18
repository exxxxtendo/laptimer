import Foundation
import CoreLocation

/// Единая точка работы с GPS.
///
/// Отличия от прежней версии:
/// - отбрасываем «мусорные» апдейты (старые, неточные, с нулевой точностью);
/// - корректно обрабатываем `speed == -1` (неизвестна) вместо того, чтобы показывать -0;
/// - публикуем точность, чтобы интерфейс мог честно показать качество сигнала;
/// - запрашиваем «всегда» разрешение, но не падаем, если дали только «при использовании».
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var lastLocation: CLLocation?
    @Published private(set) var speedKph: Double = 0
    @Published private(set) var horizontalAccuracy: Double = -1
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isUpdating: Bool = false

    /// Максимальная погрешность, при которой точку вообще стоит учитывать.
    var maxAcceptableAccuracy: Double = 50

    private let manager = CLLocationManager()
    private var backgroundModeRequested = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = false
        manager.distanceFilter = kCLDistanceFilterNone
        authorizationStatus = manager.authorizationStatus
    }

    var hasFix: Bool {
        guard let location = lastLocation else { return false }
        return horizontalAccuracy >= 0 && horizontalAccuracy <= maxAcceptableAccuracy
            && abs(location.timestamp.timeIntervalSinceNow) < 10
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            // Пытаемся «добрать» режим «Всегда» для подсчёта кругов при погашенном экране.
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    func start() {
        guard CLLocationManager.locationServicesEnabled() else { return }

        if !backgroundModeRequested,
           authorizationStatus == .authorizedAlways,
           Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
            backgroundModeRequested = true
        }

        manager.startUpdatingLocation()
        isUpdating = true
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        isUpdating = false
    }

    /// Пустая строка, если всё в порядке, иначе — что именно не так.
    var statusMessage: String? {
        switch authorizationStatus {
        case .denied, .restricted:
            return "Нет доступа к геопозиции. Включите его в Настройках."
        case .notDetermined:
            return "Разрешите доступ к геопозиции"
        default:
            if isUpdating && !hasFix {
                return "Ищем спутники…"
            }
            return nil
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.start()
            }
            if status == .authorizedAlways && !self.backgroundModeRequested {
                self.start()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= maxAcceptableAccuracy,
              abs(location.timestamp.timeIntervalSinceNow) < 10
        else { return }

        let kph: Double
        if location.speed >= 0, location.speed < 200 {
            kph = location.speed * 3.6
        } else {
            kph = 0
        }

        DispatchQueue.main.async {
            self.lastLocation = location
            self.speedKph = kph
            self.horizontalAccuracy = location.horizontalAccuracy
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Ошибки GPS не фатальны: ждём следующий апдейт.
    }
}
