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
        
        // Добавляем жест "тап"
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        map.addGestureRecognizer(tap)
        
        // Начальный вид (можно потом подвигать)
        var region = MKCoordinateRegion()
        region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        if let userLoc = map.userLocation.location?.coordinate {
            region.center = userLoc
        }
        map.setRegion(region, animated: false)
        
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        // Перерисовываем линию и маркеры только если количество точек изменилось
        guard context.coordinator.lastCount != path.count else { return }
        context.coordinator.lastCount = path.count
        
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        
        guard path.count > 1 else { return }
        
        // Рисуем линию
        let poly = MKPolyline(coordinates: path, count: path.count)
        map.addOverlay(poly)
        
        // Добавляем маркеры на каждую точку
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
        
        init(onTap: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onTap = onTap
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            onTap(coord)
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
