import SwiftUI
import MapKit

/// Карта для ручной разметки трассы: тап по карте ставит старт, потом финиш.
struct ManualTrackMapView: UIViewRepresentable {
    let path: [CLLocationCoordinate2D]
    let onTap: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.showsCompass = false
        map.showsBuildings = false
        map.pointOfInterestFilter = .excludingAll
        map.mapType = .mutedStandard
        map.overrideUserInterfaceStyle = .dark
        map.isPitchEnabled = false

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.numberOfTapsRequired = 1
        map.addGestureRecognizer(tap)

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.onTap = onTap
        context.coordinator.sync(map: map, path: path)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var onTap: (CLLocationCoordinate2D) -> Void
        private var lastKey = ""
        private var didCenterOnUser = false
        private var routeOverlay: MKOverlay?
        private var routeRequest: MKDirections?

        init(onTap: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onTap = onTap
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            onTap(coordinate)
        }

        func sync(map: MKMapView, path: [CLLocationCoordinate2D]) {
            let key = path.map { String(format: "%.5f,%.5f", $0.latitude, $0.longitude) }.joined(separator: "|")
            guard key != lastKey else { return }
            lastKey = key

            routeRequest?.cancel()
            if let routeOverlay = routeOverlay {
                map.removeOverlay(routeOverlay)
                self.routeOverlay = nil
            }
            map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })

            for (index, coordinate) in path.enumerated() {
                map.addAnnotation(TrackAnnotation(coordinate: coordinate, kind: index == 0 ? .start : .finish))
            }

            guard path.count == 2 else { return }
            loadRoute(map: map, from: path[0], to: path[1])
        }

        private func loadRoute(map: MKMapView, from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            routeRequest = directions
            directions.calculate { [weak self, weak map] response, _ in
                DispatchQueue.main.async {
                    guard let self = self, let map = map else { return }

                    if let route = response?.routes.first {
                        let casing = MKPolyline(coordinates: route.polyline.coordinates, count: route.polyline.pointCount)
                        casing.title = "casing"
                        map.addOverlay(casing)

                        let main = MKPolyline(coordinates: route.polyline.coordinates, count: route.polyline.pointCount)
                        main.title = "main"
                        map.addOverlay(main)
                        self.routeOverlay = main

                        map.setVisibleMapRect(
                            route.polyline.boundingMapRect,
                            edgePadding: UIEdgeInsets(top: 100, left: 60, bottom: 260, right: 60),
                            animated: true
                        )
                    } else {
                        let fallback = MKPolyline(coordinates: [source, destination], count: 2)
                        fallback.title = "main"
                        map.addOverlay(fallback)
                        self.routeOverlay = fallback
                    }
                }
            }
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard !didCenterOnUser, let location = userLocation.location else { return }
            didCenterOnUser = true
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 700, longitudinalMeters: 700)
            mapView.setRegion(region, animated: false)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineCap = .round
            renderer.lineJoin = .round

            if polyline.title == "casing" {
                renderer.strokeColor = UIColor.black.withAlphaComponent(0.5)
                renderer.lineWidth = 10
            } else {
                renderer.strokeColor = UIColor(Theme.accent)
                renderer.lineWidth = 5
            }
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? TrackAnnotation else { return nil }

            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "manual-marker", for: annotation) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "manual-marker")
            view.annotation = annotation
            view.canShowCallout = false
            view.animatesWhenAdded = true
            view.markerTintColor = annotation.kind == .start ? UIColor.systemGreen : UIColor(Theme.accent)
            view.glyphImage = UIImage(systemName: annotation.kind == .start ? "flag.fill" : "flag.checkered")
            view.glyphTintColor = .white
            return view
        }
    }
}
