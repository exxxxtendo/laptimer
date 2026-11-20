import SwiftUI

// MARK: - Пульсирующая точка статуса

struct PulseDot: View {
    var color: Color = Theme.accent
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: 15, height: 15)
                .scaleEffect(animate ? 1.7 : 0.6)
                .opacity(animate ? 0 : 1)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color, radius: 6)
        }
        .onAppear {
            withAnimation(Animation.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

// MARK: - Общие элементы нижней панели

/// Толстая «плакатная» плашка с косой заливкой — фирменный элемент GTA VI.
struct SlantedTag: View {
    let text: String
    var color: Color = Theme.accent

    var body: some View {
        Text(text.uppercased())
            .font(Theme.label(11))
            .kerning(1.4)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                SlantShape()
                    .fill(color)
            )
            .shadow(color: color.opacity(0.7), radius: 10)
    }
}

struct SlantShape: Shape {
    var slant: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: slant, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX - slant, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Крупная метрика: подпись сверху, значение снизу.
struct HudMetric: View {
    let label: String
    let value: String
    var tint: Color = .white
    var alignment: HorizontalAlignment = .leading
    var size: CGFloat = 19

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label.uppercased())
                .font(Theme.label(9))
                .kerning(1.0)
                .foregroundColor(Theme.textTertiary)
            Text(value)
                .font(Theme.number(size, weight: .black))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .monospacedDigit()
        }
    }
}

// MARK: - HUD: заезд по трассе

struct TrackHUD: View {
    let state: SessionState
    let currentLapTime: TimeInterval
    let lastLapTime: TimeInterval?
    let bestLapTime: TimeInterval?
    let predictedLapTime: TimeInterval?
    let delta: TimeInterval?
    let lapNumber: Int
    let speedKph: Double
    let hasReference: Bool

    var body: some View {
        VStack(spacing: 10) {
            speedBlock
            lapBlock
        }
    }

    // Верхняя строка: скорость гигантом + статус круга
    private var speedBlock: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: -8) {
                Text(Fmt.speed(speedKph))
                    .font(Theme.timer(76))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .monospacedDigit()
                    .shadow(color: Theme.accent.opacity(0.85), radius: 22)
                Text("КМ/Ч")
                    .font(Theme.label(11))
                    .kerning(3)
                    .foregroundColor(Theme.accentLemon)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 8) {
                SlantedTag(text: statusText,
                           color: state == .running ? Theme.accent : Theme.accentWarm)
                Text(deltaText)
                    .font(Theme.number(22, weight: .black))
                    .foregroundColor(deltaColor)
                    .monospacedDigit()
                    .shadow(color: deltaColor.opacity(0.8), radius: 10)
            }
        }
    }

    // Нижняя карточка: время круга + метрики
    private var lapBlock: some View {
        VStack(spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                Text("КРУГ")
                    .font(Theme.label(10))
                    .kerning(2)
                    .foregroundColor(Theme.textTertiary)
                Spacer()
                Text(Fmt.lap(currentLapTime))
                    .font(Theme.timer(46))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .monospacedDigit()
            }

            Rectangle()
                .fill(Theme.strokeStrong)
                .frame(height: 1.5)

            HStack(alignment: .top, spacing: 6) {
                HudMetric(label: "прогноз",
                          value: predictedLapTime.map(Fmt.lap) ?? "—",
                          tint: Theme.textSecondary)
                Spacer(minLength: 2)
                HudMetric(label: "последний",
                          value: lastLapTime.map(Fmt.lap) ?? "—",
                          tint: .white)
                Spacer(minLength: 2)
                HudMetric(label: "лучший",
                          value: bestLapTime.map(Fmt.lap) ?? "—",
                          tint: bestLapTime == nil ? Theme.textTertiary : Theme.positive,
                          alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.surface.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.strokeStrong, lineWidth: 1.5)
        )
        .shadow(color: Theme.accent.opacity(0.3), radius: 20)
    }

    private var statusText: String {
        switch state {
        case .running:
            return "КРУГ \(max(1, lapNumber + 1))"
        case .armed:
            return "ЖДЁМ СТАРТ"
        default:
            return "ПАУЗА"
        }
    }

    private var deltaText: String {
        guard hasReference, delta != nil else { return "—" }
        return Fmt.delta(delta)
    }

    private var deltaColor: Color {
        guard hasReference, let delta = delta else { return Theme.textTertiary }
        if delta < 0 { return Theme.positive }
        if delta > 0 { return Theme.negative }
        return .white
    }
}

// MARK: - HUD: свободный заезд

struct FreeHUD: View {
    let state: SessionState
    let currentLapTime: TimeInterval
    let speedKph: Double
    let distanceMeters: Double
    let topSpeedKph: Double
    let lapCount: Int
    let bestLapTime: TimeInterval?

    var body: some View {
        VStack(spacing: 10) {
            speedBlock
            timeBlock
        }
    }

    private var speedBlock: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: -8) {
                Text(Fmt.speed(speedKph))
                    .font(Theme.timer(76))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .monospacedDigit()
                    .shadow(color: Theme.accent.opacity(0.85), radius: 22)
                Text("КМ/Ч")
                    .font(Theme.label(11))
                    .kerning(3)
                    .foregroundColor(Theme.accentLemon)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 8) {
                SlantedTag(text: statusText,
                           color: state == .running ? Theme.accent : Theme.accentWarm)
                if lapCount > 0 {
                    Text("\(lapCount) КРУГ")
                        .font(Theme.number(14, weight: .black))
                        .foregroundColor(Theme.accentCyan)
                        .kerning(1)
                }
            }
        }
    }

    private var timeBlock: some View {
        VStack(spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                Text("ВРЕМЯ")
                    .font(Theme.label(10))
                    .kerning(2)
                    .foregroundColor(Theme.textTertiary)
                Spacer()
                Text(Fmt.lap(currentLapTime))
                    .font(Theme.timer(46))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .monospacedDigit()
            }

            Rectangle()
                .fill(Theme.strokeStrong)
                .frame(height: 1.5)

            HStack(alignment: .top, spacing: 6) {
                HudMetric(label: "дистанция", value: Fmt.distance(distanceMeters), tint: .white)
                Spacer(minLength: 2)
                HudMetric(label: "макс. скорость", value: Fmt.speed(topSpeedKph), tint: Theme.accentLemon)
                Spacer(minLength: 2)
                HudMetric(label: "лучший круг",
                          value: bestLapTime.map(Fmt.lap) ?? "—",
                          tint: Theme.positive,
                          alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.surface.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.strokeStrong, lineWidth: 1.5)
        )
        .shadow(color: Theme.accent.opacity(0.3), radius: 20)
    }

    private var statusText: String {
        switch state {
        case .running:
            return "ЗАЕЗД"
        case .paused:
            return "ПАУЗА"
        default:
            return "ГОТОВ"
        }
    }
}
