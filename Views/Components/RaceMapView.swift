import SwiftUI
import MapKit

struct RaceMapView: UIViewRepresentable {
    let track: Track?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.showsCompass = true
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        if context.coordinator.lastTrackID != track?.id {
            map.removeOverlays(map.overlays)
            
            if let points = track?.points, !points.isEmpty {
                if points.count == 2 {
                    let source = points[0].coordinate
                    let dest = points[1].coordinate
                    
                    let request = MKDirections.Request()
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest))
                    request.transportType = .automobile
                    
                    MKDirections(request: request).calculate { response, error in
                        if let route = response?.routes.first {
                            map.addOverlay(route.polyline)
                        }
                    }
                } else if points.count > 2 {
                    let coords = points.map { $0.coordinate }
                    let line = MKPolyline(coordinates: coords, count: coords.count)
                    map.addOverlay(line)
                }
            }
            context.coordinator.lastTrackID = track?.id
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastTrackID: UUID?
        var didZoom = false
        
        // Как только GPS найдет нас, делаем зум и включаем режим навигатора
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard let loc = userLocation.location else { return }
            
            if !didZoom {
                didZoom = true
                let region = MKCoordinateRegion(center: loc.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
                mapView.setRegion(region, animated: true)
                mapView.userTrackingMode = .followWithHeading
            }
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
