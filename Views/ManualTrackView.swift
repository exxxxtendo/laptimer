import SwiftUI
import MapKit
import CoreLocation

struct ManualTrackView: View {
    @EnvironmentObject var store: TrackStore
    @Environment(\.dismiss) private var dismiss

    @State private var path: [CLLocationCoordinate2D] = []
    @State private var showNameSheet = false
    @State private var trackName = ""
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        ZStack {
            TapMapView(path: $path, region: $mapRegion)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                VStack(spacing: 12) {
                    Text("Тапайте по карте, чтобы добавить точки")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())

                    Button {
                        if path.count > 2 {
                            trackName = "Трасса \(store.tracks.count + 1)"
                            showNameSheet = true
                        }
                    } label: {
                        Text("Сохранить (\(path.count) точек)")
                            .font(.title3.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(path.count > 2 ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 16))
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showNameSheet) {
            NavigationView {
                Form { TextField("Название трассы", text: $trackName) }
                    .navigationTitle("Сохранить")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Отмена") { showNameSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Сохранить") { save() }
                                .disabled(trackName.isEmpty)
                        }
                    }
            }
        }
    }

    private func save() {
        let coords = path.map { CodableCoordinate($0) }
        var length: Double = 0
        for i in 1..<path.count {
            let p1 = CLLocation(latitude: path[i-1].latitude, longitude: path[i-1].longitude)
            let p2 = CLLocation(latitude: path[i].latitude, longitude: path[i].longitude)
            length += p1.distance(from: p2)
        }
        
        let track = Track(
            name: trackName,
            points: coords,
            startPoint: CodableCoordinate(path[0]),
            lengthMeters: length
        )
        store.add(track)
        showNameSheet = false
        dismiss()
    }
}

struct TapMapView: UIViewRepresentable {
    @Binding var path: [CLLocationCoordinate2D]
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.overrideUserInterfaceStyle = .dark
        
        let gesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTap(_:)))
        map.addGestureRecognizer(gesture)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.setRegion(region, animated: false)
        map.removeOverlays(map.overlays)
        if path.count > 1 {
            map.addOverlay(MKPolyline(coordinates: path, count: path.count))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TapMapView
        init(_ parent: TapMapView) { self.parent = parent }

        @objc func didTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            parent.path.append(coordinate)
            mapView.removeOverlays(mapView.overlays)
            if parent.path.count > 1 {
                mapView.addOverlay(MKPolyline(coordinates: parent.path, count: parent.path.count))
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.strokeColor = UIColor.systemBlue
                r.lineWidth = 5
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
