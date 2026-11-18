import SwiftUI

// MARK: - Пульсирующая точка статуса

struct PulseDot: View {
    var color: Color = Theme.accent
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: 14, height: 14)
                .scaleEffect(animate ? 1.5 : 0.7)
                .opacity(animate ? 0 : 1)
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
        }
        .onAppear {
            withAnimation(Animation.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                animate = true
            }
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
        Panel {
            VStack(spacing: 12) {
                header

                HStack(alignment: .bottom, spacing: 10) {
                    timeBlock
                    Spacer(minLength: 4)
                    speedBlock
                }

                Rectangle()
                    .fill(Theme.stroke)
                    .frame(height: 1)

                HStack(alignment: .top, spacing: 8) {
                    LabeledValue(
                        label: "прогноз",
                        value: predictedLapTime.map(Fmt.lap) ?? "—",
                        tint: Theme.textSecondary
                    )
                    Spacer(minLength: 4)
                    LabeledValue(
                        label: "последний",
                        value: lastLapTime.map(Fmt.lap) ?? "—",
                        tint: Theme.textPrimary
                    )
                    Spacer(minLength: 4)
                    LabeledValue(
                        label: "лучший",
                        value: bestLapTime.map(Fmt.lap) ?? "—",
                        tint: bestLapTime == nil ? Theme.textSecondary : Theme.positive,
                        alignment: .trailing
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 7) {
                PulseDot(color: state == .running ? Theme.accent : Theme.warning)
                Text(statusText)
                    .font(Theme.label(11))
                    .foregroundColor(Theme.textPrimary)
                    .kerning(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.07)))

            Spacer()

            HStack(spacing: 6) {
                Text("Δ")
                    .font(Theme.label(11))
                    .foregroundColor(Theme.textTertiary)
                Text(hasReference ? Fmt.delta(delta) : "—")
                    .font(Theme.number(14, weight: .heavy))
                    .foregroundColor(deltaColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(deltaBackground))
        }
    }

    private var timeBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("время круга")
                .font(Theme.label(10))
                .foregroundColor(Theme.textTertiary)
                .kerning(0.8)
            Text(Fmt.lap(currentLapTime))
                .font(Theme.timer(44))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .monospacedDigit()
        }
    }

    private var speedBlock: some View {
        VStack(alignment: .trailing, spacing: -4) {
            Text(Fmt.speed(speedKph))
                .font(Theme.number(38, weight: .black))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .monospacedDigit()
            Text("км/ч")
                .font(Theme.label(9))
                .foregroundColor(Theme.textTertiary)
                .kerning(0.6)
        }
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

    private var deltaColor: Color {
        guard let delta = delta else { return Theme.textSecondary }
        if delta < 0 { return Theme.positive }
        if delta > 0 { return Theme.negative }
        return Theme.textSecondary
    }

    private var deltaBackground: Color {
        guard let delta = delta else { return Color.white.opacity(0.07) }
        if delta < 0 { return Theme.positive.opacity(0.14) }
        if delta > 0 { return Theme.negative.opacity(0.14) }
        return Color.white.opacity(0.07)
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
        Panel {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    HStack(spacing: 7) {
                        PulseDot(color: state == .running ? Theme.accent : Theme.textTertiary)
                        Text(statusText)
                            .font(Theme.label(11))
                            .foregroundColor(Theme.textPrimary)
                            .kerning(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.07)))

                    Spacer()

                    if lapCount > 0 {
                        Text("КРУГОВ: \(lapCount)")
                            .font(Theme.label(11))
                            .foregroundColor(Theme.textSecondary)
                            .kerning(0.6)
                    }
                }

                HStack(alignment: .bottom, spacing: 10) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("время")
                            .font(Theme.label(10))
                            .foregroundColor(Theme.textTertiary)
                            .kerning(0.8)
                        Text(Fmt.lap(currentLapTime))
                            .font(Theme.timer(46))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.45)
                            .monospacedDigit()
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: -4) {
                        Text(Fmt.speed(speedKph))
                            .font(Theme.number(38, weight: .black))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        Text("км/ч")
                            .font(Theme.label(9))
                            .foregroundColor(Theme.textTertiary)
                            .kerning(0.6)
                    }
                }

                Rectangle()
                    .fill(Theme.stroke)
                    .frame(height: 1)

                HStack(alignment: .top, spacing: 8) {
                    LabeledValue(label: "дистанция", value: Fmt.distance(distanceMeters), tint: Theme.textPrimary)
                    Spacer(minLength: 4)
                    LabeledValue(label: "макс. скорость", value: Fmt.speed(topSpeedKph), tint: Theme.textPrimary)
                    Spacer(minLength: 4)
                    LabeledValue(label: "лучший круг",
                                 value: bestLapTime.map(Fmt.lap) ?? "—",
                                 tint: Theme.positive,
                                 alignment: .trailing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
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
