import SwiftUI
import UIKit
import MapKit

/// Рисует превью трассы (карта + линия) для карточек списка.
///
/// Линия строится по `track.points`. У трасс, созданных «по дорогам»,
/// там лежит полная геометрия маршрута, поэтому превью совпадает с заездом.
/// Если геометрии ещё нет (старые трассы), она подгружается один раз.
enum RouteSnapshotService {
    private static let cache = NSCache<NSString, UIImage>()

    static func image(for track: Track,
                      size: CGSize,
                      completion: @escaping (UIImage?) -> Void) {
        let key = cacheKey(for: track, size: size)
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }

        if track.needsRouteGeometry {
            // Старая трасса без геометрии: сначала дотягиваем маршрут.
            RouteGeometryLoader.load(for: track) { updated in
                guard let updated = updated else {
                    render(track: track, size: size, key: key, completion: completion)
                    return
                }
                render(track: updated, size: size, key: key, completion: completion)
            }
            return
        }

        render(track: track, size: size, key: key, completion: completion)
    }

    static func clearCache() {
        cache.removeAllObjects()
    }

    // MARK: - Приватное

    private static func cacheKey(for track: Track, size: CGSize) -> NSString {
        "\(track.id.uuidString)-\(Int(size.width))x\(Int(size.height))-\(track.points.count)-\(track.hasRouteGeometry)" as NSString
    }

    private static func render(track: Track,
                               size: CGSize,
                               key: NSString,
                               completion: @escaping (UIImage?) -> Void) {
        let coordinates: [CLLocationCoordinate2D]
        if track.points.count > 1 {
            coordinates = track.points.map { $0.coordinate }
        } else {
            coordinates = [track.startPoint.coordinate, track.finishPoint.coordinate]
        }

        let options = MKMapSnapshotter.Options()
        options.size = size
        options.mapType = .mutedStandard
        options.showsBuildings = false
        options.pointOfInterestFilter = .excludingAll
        options.traitCollection = UITraitCollection(userInterfaceStyle: .dark)
        if let region = Geo.region(for: track.points.isEmpty ? [track.startPoint] : track.points, paddingMeters: 90) {
            options.region = region
        }

        MKMapSnapshotter(options: options).start { snapshot, _ in
            // Рисуем на главном потоке: UIKit не любит фоновую отрисовку.
            DispatchQueue.main.async {
                guard let snapshot = snapshot else {
                    completion(nil)
                    return
                }

                let renderer = UIGraphicsImageRenderer(size: size)
                let image = renderer.image { _ in
                    snapshot.image.draw(at: .zero)

                    guard coordinates.count > 1 else { return }

                    let path = UIBezierPath()
                    for (index, coordinate) in coordinates.enumerated() {
                        let point = snapshot.point(for: coordinate)
                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }

                    let casing = path.copy() as? UIBezierPath
                    casing?.lineWidth = 7
                    casing?.lineCapStyle = .round
                    casing?.lineJoinStyle = .round
                    UIColor.black.withAlphaComponent(0.55).setStroke()
                    casing?.stroke()

                    path.lineWidth = 3.5
                    path.lineCapStyle = .round
                    path.lineJoinStyle = .round
                    UIColor(Theme.accent).setStroke()
                    path.stroke()

                    // Точка старта.
                    if let first = coordinates.first {
                        let point = snapshot.point(for: first)
                        let dot = UIBezierPath(ovalIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))
                        UIColor.white.setFill()
                        dot.fill()
                    }
                }

                cache.setObject(image, forKey: key)
                completion(image)
            }
        }
    }
}

struct TrackSnapshotView: View {
    let track: Track
    var height: CGFloat = 108

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Theme.surfaceElevated
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.textTertiary))
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
        .onAppear(perform: load)
    }

    private func load() {
        guard image == nil else { return }
        RouteSnapshotService.image(for: track, size: CGSize(width: 360, height: height)) { result in
            if let result = result {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.image = result
                }
            }
        }
    }
}
