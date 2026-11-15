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
        
        // Убираем старую линию и старые булавки
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        
        // ВАЖНО: сначала показываем булавки для всех точек (даже если одна)
        for (index, coord) in path.enumerated() {
            let pin = MKPointAnnotation()
            pin.coordinate = coord
            pin.title = index == 0 ? "Старт" : "Финиш"
            map.addAnnotation(pin)
        }
        
        // Если две точки — строим маршрут по дорогам (как в сохраненной трассе)
        if path.count == 2 {
            context.coordinator.fetchRoute(from: path[0], to: path[1], on: map)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastCount = 0
        let onTap: (CLLocationCoordinate2D) -> Void
        var didZoom = false
        var currentRouteOverlay: MKOverlay?
        
        init(onTap: @escaping (CLLocationCoordinate2D) -> Void) { self.onTap = onTap }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            onTap(coord)
        }

        // Однократный зум к пользователю при старте
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard !didZoom, let location = userLocation.location else { return }
            didZoom = true
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }
        
        // Запрос маршрута у Apple
        func fetchRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, on mapView: MKMapView) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            directions.calculate { [weak self] response, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let old = self.currentRouteOverlay {
                        mapView.removeOverlay(old)
                    }
                    
                    if let route = response?.routes.first {
                        // Маршрут по дорогам найден
                        mapView.addOverlay(route.polyline)
                        self.currentRouteOverlay = route.polyline
                        
                        // Подгоняем камеру, чтобы видеть весь маршрут
                        mapView.setVisibleMapRect(
                            route.polyline.boundingMapRect,
                            edgePadding: UIEdgeInsets(top: 80, left: 80, bottom: 250, right: 80),
                            animated: true
                        )
                    } else {
                        // Запасной вариант: если Apple не нашла дорог, рисуем прямую
                        let fallback = MKPolyline(coordinates: [source, destination], count: 2)
                        mapView.addOverlay(fallback)
                        self.currentRouteOverlay = fallback
                        print("Не удалось построить маршрут: \(error?.localizedDescription ?? "")")
                    }
                }
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
        
        // Настройка булавок (зеленая старт, красная финиш)
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
