import SwiftUI
import MapKit

struct ManualTrackMapView: UIViewRepresentable {
    let path: [CLLocationCoordinate2D]
    let onTap: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark
        
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        map.addGestureRecognizer(tap)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        guard context.coordinator.lastCount != path.count else { return }
        context.coordinator.lastCount = path.count
        
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        
        guard path.count > 1 else { return }
        let poly = MKPolyline(coordinates: path, count: path.count)
        map.addOverlay(poly)
        
        for coord in path {
            let pin = MKPointAnnotation()
            pin.coordinate = coord
            map.addAnnotation(pin)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastCount = 0
        let onTap: (CLLocationCoordinate2D) -> Void
        var didZoom = false
        
        init(onTap: @escaping (CLLocationCoordinate2D) -> Void) { self.onTap = onTap }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            onTap(coord)
        }

        // ТОТ САМЫЙ ЗУМ: ждем GPS и центрируемся на пользователе
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard !didZoom, let location = userLocation.location else { return }
            didZoom = true
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.strokeColor = UIColor.systemBlue
                r.lineWidth = 5
                r.lineCap = .round
                r.lineJoin = .round
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let id = "pin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.markerTintColor = .systemBlue
            view.animatesWhenAdded = true
            return view
        }
    }
}
