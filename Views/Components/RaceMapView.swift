import SwiftUI
import MapKit

struct RaceMapView: UIViewRepresentable {
    let track: Track?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        map.showsCompass = false; map.showsScale = false
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        if context.coordinator.lastTrackID != track?.id {
            map.removeOverlays(map.overlays)
            if let points = track?.points, points.count > 1 {
                let coords = points.map { $0.coordinate }
                map.addOverlay(MKPolyline(coordinates: coords, count: coords.count))
            }
            context.coordinator.lastTrackID = track?.id
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastTrackID: UUID?
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.strokeColor = UIColor.systemBlue
                r.lineWidth = 5; r.lineCap = .round; r.lineJoin = .round
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
