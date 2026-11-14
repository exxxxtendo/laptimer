import SwiftUI
import MapKit

struct RecordingMapView: UIViewRepresentable {
    let path: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.userTrackingMode = .followWithHeading // Режим навигатора
        map.showsCompass = true
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark
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
        var didZoom = false
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard !didZoom, let location = userLocation.location else { return }
            didZoom = true
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 400, longitudinalMeters: 400)
            mapView.setRegion(region, animated: true)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.strokeColor = UIColor.systemGreen
                r.lineWidth = 5
                r.lineCap = .round
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
