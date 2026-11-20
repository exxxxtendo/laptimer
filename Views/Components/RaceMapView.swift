import SwiftUI
import MapKit

/// Маркер старта/финиша на карте.
final class TrackAnnotation: NSObject, MKAnnotation {
    enum Kind {
        case start
        case finish
    }

    let kind: Kind
    @objc dynamic var coordinate: CLLocationCoordinate2D

    var title: String? {
        kind == .start ? "Старт" : "Финиш"
    }

    init(coordinate: CLLocationCoordinate2D, kind: Kind) {
        self.coordinate = coordinate
        self.kind = kind
        super.init()
    }
}

/// Карта заезда: линия трассы, старт/финиш, слежение за пользователем.
struct RaceMapView: UIViewRepresentable {
    let track: Track?
    let followsUser: Bool
    var recenterToken: Int = 0

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.showsCompass = false
        map.showsScale = false
        map.showsBuildings = false
        map.showsTraffic = false
        map.pointOfInterestFilter = .excludingAll
        map.mapType = .mutedStandard
        map.overrideUserInterfaceStyle = .dark
        map.isPitchEnabled = false
        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "track-marker")
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.sync(map: map, track: track)

        if context.coordinator.lastRecenterToken != recenterToken {
            context.coordinator.lastRecenterToken = recenterToken
            context.coordinator.didCenterOnUser = false
        }

        let mode: MKUserTrackingMode = followsUser ? .followWithHeading : .none
        if map.userTrackingMode != mode {
            map.setUserTrackingMode(mode, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private var loadedTrackID: UUID?
        private var didCenterOnUser = false
        private var routeRequest: MKDirections?
        private var lastRecenterToken = 0

        func sync(map: MKMapView, track: Track?) {
            let trackID = track?.id
            guard loadedTrackID != trackID else { return }
            loadedTrackID = trackID

            routeRequest?.cancel()
            map.removeOverlays(map.overlays)
            map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })

            guard let track = track else { return }

            map.addAnnotation(TrackAnnotation(coordinate: track.startPoint.coordinate, kind: .start))
            if !track.isLoop {
                map.addAnnotation(TrackAnnotation(coordinate: track.finishPoint.coordinate, kind: .finish))
            }

            if track.isRouted, track.points.count <= 2 {
                loadRoute(map: map, track: track)
            } else if track.points.count > 1 {
                addPolyline(map: map, coordinates: track.points.map { $0.coordinate })
                if let region = Geo.region(for: track.points, paddingMeters: 140) {
                    map.setRegion(region, animated: false)
                }
            }
        }

        private func addPolyline(map: MKMapView, coordinates: [CLLocationCoordinate2D]) {
            guard coordinates.count > 1 else { return }

            let casing = MKPolyline(coordinates: coordinates, count: coordinates.count)
            casing.title = "casing"
            map.addOverlay(casing)

            let main = MKPolyline(coordinates: coordinates, count: coordinates.count)
            main.title = "main"
            map.addOverlay(main)
        }

        private func loadRoute(map: MKMapView, track: Track) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: track.startPoint.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: track.finishPoint.coordinate))
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            routeRequest = directions
            directions.calculate { [weak map] response, _ in
                DispatchQueue.main.async {
                    guard let map = map else { return }
                    if let route = response?.routes.first {
                        self.addPolyline(map: map, coordinates: route.polyline.coordinates)
                        map.setVisibleMapRect(
                            route.polyline.boundingMapRect,
                            edgePadding: UIEdgeInsets(top: 120, left: 80, bottom: 340, right: 80),
                            animated: false
                        )
                    } else {
                        self.addPolyline(map: map, coordinates: [track.startPoint.coordinate, track.finishPoint.coordinate])
                    }
                }
            }
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard !didCenterOnUser, let location = userLocation.location else { return }
            didCenterOnUser = true
            guard loadedTrackID == nil else { return }
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 600, longitudinalMeters: 600)
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
                renderer.strokeColor = UIColor.black.withAlphaComponent(0.55)
                renderer.lineWidth = 11
            } else {
                renderer.strokeColor = UIColor(Theme.accent)
                renderer.lineWidth = 5
            }
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? TrackAnnotation else { return nil }

            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "track-marker", for: annotation) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "track-marker")
            view.annotation = annotation
            view.canShowCallout = false
            view.animatesWhenAdded = true
            view.markerTintColor = annotation.kind == .start ? UIColor(Theme.positive) : UIColor(Theme.accent)
            view.glyphTintColor = .white
            view.glyphImage = UIImage(systemName: annotation.kind == .start ? "flag.fill" : "flag.checkered")
            return view
        }
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var result: [CLLocationCoordinate2D] = []
        result.reserveCapacity(pointCount)
        let points = self.points()
        for index in 0..<pointCount {
            result.append(points[index].coordinate)
        }
        return result
    }
}
