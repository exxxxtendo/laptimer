import SwiftUI
import MapKit

struct RaceMapView: UIViewRepresentable {
    let track: Track?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        // Режим езды за пользователем с поворотом камеры по направлению движения (как навигатор)
        map.userTrackingMode = .followWithHeading
        map.showsCompass = true
        map.showsScale = false
        map.pointOfInterestFilter = .excludingAll
        map.overrideUserInterfaceStyle = .dark
        
        // Начальный зум (чем больше число, тем ближе камера)
        var region = MKCoordinateRegion()
        region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        
        if let startPoint = track?.startPoint.coordinate {
            region.center = startPoint
        }
        map.setRegion(region, animated: false)
        
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
    }
}
