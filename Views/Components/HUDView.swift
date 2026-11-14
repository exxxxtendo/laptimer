import SwiftUI

struct HUDView: View {
    let current: TimeInterval
    let last: TimeInterval?
    let best: TimeInterval?
    let laps: Int
    let speedKph: Double
    let theme: AppTheme

    var body: some View {
        Group {
            switch theme {
            case .ios:
                glassTheme
            case .raceChrono:
                raceChronoTheme
            case .modern:
                modernTheme
            }
        }
    }

    // 1. СТЕКЛО (iOS)
    private var glassTheme: some View {
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
        .foregroundColor(.primary)
    }

    // 2. RACECHRONO (Классика - Синий блок)
    private var raceChronoTheme: some View {
        VStack(spacing: 0) {
            // Верхняя часть: время
            HStack {
                VStack(spacing: 0) {
                    Text(Fmt.lap(current))
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("Текущий круг").font(.caption).foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                VStack(spacing: 0) {
                    Text(Fmt.speed(speedKph))
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("км/ч").font(.caption).foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(Color.blue)

            // Нижняя часть: инфа
            HStack {
                smallChronoStat("Прошлый", last.map(Fmt.lap) ?? "-:--.---")
                Divider().background(Color.gray)
                smallChronoStat("Лучший", best.map(Fmt.lap) ?? "-:--.---")
                Divider().background(Color.gray)
                smallChronoStat("Кругов", "\(laps)")
            }
            .padding(.vertical, 12)
            .background(Color.black)
            .foregroundColor(.white)
        }
    }

    // 3. MODERN (Современный - Темные карточки)
    private var modernTheme: some View {
        VStack(spacing: 16) {
            // Блок времени
            VStack(spacing: 4) {
                Text("ТЕКУЩИЙ КРУГ").font(.caption2.weight(.bold)).foregroundColor(.gray)
                Text(Fmt.lap(current))
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(white: 0.2), lineWidth: 1))

            // Сетка статов
            HStack(spacing: 12) {
                modernStatCard(title: "Скорость", value: Fmt.speed(speedKph), unit: "км/ч", color: .cyan)
                modernStatCard(title: "Прошлый", value: last.map(Fmt.lap) ?? "--", unit: "", color: .white)
                modernStatCard(title: "Лучший", value: best.map(Fmt.lap) ?? "--", unit: "", color: .green)
            }
        }
    }

    // Вспомогательные функции
    private func metric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline).monospacedDigit().foregroundColor(color)
        }
    }
    private func smallChronoStat(_ label: String, _ value: String) -> some View {
        VStack {
            Text(label).font(.caption2).foregroundColor(.gray)
            Text(value).font(.system(size: 16, weight: .semibold, design: .monospaced))
        }.frame(maxWidth: .infinity)
    }
    private func modernStatCard(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2).foregroundColor(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(color)
                if !unit.isEmpty { Text(unit).font(.caption2).foregroundColor(.gray) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}
