import SwiftUI
import MapKit

struct RaceMapView: UIViewRepresentable {
    let track: Track?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.userTrackingMode = .followWithHeading
        map.showsCompass = true
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        if context.coordinator.lastTrackID != track?.id {
            map.removeOverlays(map.overlays)
            if let points = track?.points, points.count > 1 {
                let coords = points.map { $0.coordinate }
                let line = MKPolyline(coordinates: coords, count: coords.count)
                map.addOverlay(line)
            }
            context.coordinator.lastTrackID = track?.id
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastTrackID: UUID?
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
                r.strokeColor = UIColor.systemBlue
                r.lineWidth = 6
                r.lineCap = .round
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
