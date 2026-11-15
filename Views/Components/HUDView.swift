import SwiftUI

struct HUDView: View {
    let current: TimeInterval
    let last: TimeInterval?
    let best: TimeInterval?
    let laps: Int
    let speedKph: Double
    let theme: AppTheme // Добавили параметр темы

    var body: some View {
        switch theme {
        case .raceChrono:
            raceChronoView
        case .standard:
            standardView
        case .modern:
            modernView
        }
    }
    
    // 1. СТИЛЬ RACECHRONO (Минимализм, много данных)
    private var raceChronoView: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("TIME").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                    Text(Fmt.lap(current)).font(.system(size: 46, weight: .bold, design: .monospaced))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("SPEED").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                    Text(Fmt.speed(speedKph)).font(.system(size: 46, weight: .bold, design: .monospaced))
                }
            }
            HStack {
                Text("LAST: \(last.map(Fmt.lap) ?? "--")").font(.system(size: 14, design: .monospaced))
                Spacer()
                Text("BEST: \(best.map(Fmt.lap) ?? "--")").font(.system(size: 14, design: .monospaced)).foregroundColor(.green)
                Spacer()
                Text("LAPS: \(laps)").font(.system(size: 14, design: .monospaced))
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // 2. ОБЫЧНЫЙ СТИЛЬ (Стекло iOS)
    private var standardView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Круг \(laps + 1)").font(.caption).foregroundColor(.secondary)
                    Text(Fmt.lap(current)).font(.system(size: 56, weight: .bold, design: .rounded)).monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("км/ч").font(.caption).foregroundColor(.secondary)
                    Text(Fmt.speed(speedKph)).font(.system(size: 56, weight: .bold, design: .rounded)).monospacedDigit()
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
    
    // 3. СОВРЕМЕННЫЙ СТИЛЬ (Неон, градиенты)
    private var modernView: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ТЕКУЩИЙ КРУГ").font(.system(size: 12, weight: .black)).foregroundColor(.gray)
                    Text(Fmt.lap(current))
                        .font(.system(size: 58, weight: .heavy, design: .monospaced))
                        .shadow(color: .blue.opacity(0.8), radius: 10)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("СКОРОСТЬ").font(.system(size: 12, weight: .black)).foregroundColor(.gray)
                    Text(Fmt.speed(speedKph)).font(.system(size: 58, weight: .heavy, design: .monospaced))
                }
            }
            Rectangle().fill(LinearGradient(colors: [.clear, .gray.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
            HStack {
                metric("ЛУЧШИЙ", best.map(Fmt.lap) ?? "--:--.---", .green)
                Spacer()
                metric("ПРОШЛЫЙ", last.map(Fmt.lap) ?? "--:--.---", .orange)
                Spacer()
                metric("КРУГОВ", "\(laps)", .white)
            }
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.08, green: 0.08, blue: 0.1)))
    }

    private func metric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline).monospacedDigit().foregroundColor(color)
        }
    }
}
