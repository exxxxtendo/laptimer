import SwiftUI
import MapKit

/// Карта записи трека: рисует пройденный путь «на лету».
struct RecordingMapView: UIViewRepresentable {
    let path: [CLLocationCoordinate2D]
    let followsUser: Bool

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
        map.userTrackingMode = followsUser ? .followWithHeading : .none
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.sync(map: map, path: path)

        let mode: MKUserTrackingMode = followsUser ? .followWithHeading : .none
        if map.userTrackingMode != mode {
            map.setUserTrackingMode(mode, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private var lastCount = 0
        private var didCenterOnUser = false
        private var casing: MKPolyline?
        private var main: MKPolyline?

        func sync(map: MKMapView, path: [CLLocationCoordinate2D]) {
            guard lastCount != path.count else { return }
            lastCount = path.count
            guard path.count > 1 else { return }

            if let casing = casing { map.removeOverlay(casing) }
            if let main = main { map.removeOverlay(main) }

            let casingPolyline = MKPolyline(coordinates: path, count: path.count)
            casingPolyline.title = "casing"
            map.addOverlay(casingPolyline)
            casing = casingPolyline

            let mainPolyline = MKPolyline(coordinates: path, count: path.count)
            mainPolyline.title = "main"
            map.addOverlay(mainPolyline)
            main = mainPolyline
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard !didCenterOnUser, let location = userLocation.location else { return }
            didCenterOnUser = true
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
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
                renderer.strokeColor = UIColor(Theme.positive)
                renderer.lineWidth = 5
            }
            return renderer
        }
    }
}
