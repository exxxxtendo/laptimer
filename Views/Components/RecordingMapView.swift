import SwiftUI
import MapKit

struct RecordingMapView: UIViewRepresentable {
    let path: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.userTrackingMode = .none // Отключаем жесткое следование, чтобы карта могла отдаляться
        map.showsCompass = true
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark
        
        // Начальный зум чуть шире, чтобы было видно окрестности
        var region = MKCoordinateRegion()
        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        if let userLoc = map.userLocation.location?.coordinate {
            region.center = userLoc
        }
        map.setRegion(region, animated: false)
        
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        // Если количество точек изменилось
        guard context.coordinator.lastCount != path.count, path.count > 1 else { return }
        context.coordinator.lastCount = path.count
        
        // Перерисовываем линию
        if let existing = context.coordinator.polyline { map.removeOverlay(existing) }
        let poly = MKPolyline(coordinates: path, count: path.count)
        context.coordinator.polyline = poly
        map.addOverlay(poly)
        
        // МАГИЯ: Автоматически подстраиваем камеру так, 
        // чтобы был виден ВЕСЬ нарисованный трек
        if path.count > 2 {
            map.setVisibleMapRect(
                poly.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 150, right: 60), // Отступы, чтобы кнопки не перекрывали линию
                animated: true
            )
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastCount = 0
        var polyline: MKPolyline?
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.strokeColor = UIColor.systemGreen
                r.lineWidth = 6
                r.lineCap = .round
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
