import SwiftUI
import MapKit

struct RecordingMapView: UIViewRepresentable {
    let path: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        // Следим за пользователем, поворачивая камеру
        map.userTrackingMode = .followWithHeading
        map.showsCompass = true
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark
        
        // Сразу приближаем карту
        var region = MKCoordinateRegion()
        region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        
        // Если мы уже начали записывать, центрируемся по первой точке. Если нет — по текущей геопозиции.
        if let first = path.first {
            region.center = first
        } else if let userLoc = map.userLocation.location?.coordinate {
            region.center = userLoc
        }
        map.setRegion(region, animated: false)
        
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        guard context.coordinator.lastCount != path.count, path.count > 1 else { return }
        context.coordinator.lastCount = path.count
        if let existing = context.coordinator.polyline { map.removeOverlay(existing) }
        let poly = MKPolyline(coordinates: path, count: path.count)
        context.coordinator.polyline = poly
        map.addOverlay(poly)
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
