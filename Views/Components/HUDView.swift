import SwiftUI

struct HUDView: View {
    let current: TimeInterval
    let last: TimeInterval?
    let best: TimeInterval?
    let laps: Int
    let speedKph: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Круг \(laps + 1)").font(.caption).foregroundColor(.secondary)
                    Text(Fmt.lap(current))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("км/ч").font(.caption).foregroundColor(.secondary)
                    Text(Fmt.speed(speedKph))
                        .font(.system(size: 56, weight: .bold, design: .rounded)).monospacedDigit()
                }
            }
            Divider()
            HStack {
                metric("Прошлый", last.map(Fmt.lap) ?? "--:--.---", .primary)
                Spacer()
                metric("Лучший", best.map(Fmt.lap) ?? "--:--.---", .green)
                Spacer()
                metric("Кругов", "\(laps)", .primary)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
    private func metric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline).monospacedDigit().foregroundColor(color)
        }
    }
}
