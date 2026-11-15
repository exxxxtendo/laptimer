import SwiftUI
import MapKit

struct ManualTrackMapView: UIViewRepresentable {
    @Binding var path: [CLLocationCoordinate2D]
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
        // Если точек нет или их слишком много (для запроса маршрута нужно ровно 2)
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        
        // Ставим маркеры на все выбранные точки
        for (index, coord) in path.enumerated() {
            let pin = MKPointAnnotation()
            pin.coordinate = coord
            pin.title = index == 0 ? "Старт" : "Финиш"
            map.addAnnotation(pin)
        }
        
        // Если есть ровно 2 точки, запрашиваем маршрут у Apple
        if path.count == 2 {
            context.coordinator.fetchRoute(from: path[0], to: path[1], on: map)
        } else if path.count > 1 {
            // Если точек больше 2 (на всякий случай), рисуем прямую
            let poly = MKPolyline(coordinates: path, count: path.count)
            map.addOverlay(poly)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ManualTrackMapView
        var routePolyline: MKPolyline?
        
        init(parent: ManualTrackMapView) { self.parent = parent }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            parent.onTap(coord)
        }

        func fetchRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, on mapView: MKMapView) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = .automobile // Ищем автомобильные дороги
            
            let directions = MKDirections(request: request)
            directions.calculate { [weak self] response, error in
                guard let self = self, let route = response?.routes.first else {
                    print("Не удалось построить маршрут: \(error?.localizedDescription ?? "")")
                    return
                }
                // Рисуем реальный маршрут
                let polyline = route.polyline
                mapView.addOverlay(polyline)
                self.routePolyline = polyline
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.strokeColor = UIColor.systemBlue
                r.lineWidth = 6
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
            view.markerTintColor = annotation.title == "Старт" ? .systemGreen : .systemRed
            view.animatesWhenAdded = true
            return view
        }
    }
}
