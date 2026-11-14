import SwiftUI
import MapKit

struct RecordingMapView: UIViewRepresentable {
    let path: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.userTrackingMode = .followWithHeading // Камера сама полетит к вам
        map.showsCompass = true
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark
        
        // Убрали принудительный setRegion, чтобы не прыгало в Москву
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
