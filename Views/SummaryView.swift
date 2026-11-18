import SwiftUI

/// Итоги заезда: лучший круг, статистика, список кругов.
struct SummaryView: View {
    let session: SessionResult

    @EnvironmentObject private var records: RecordsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Grabber()
                .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if let best = session.best {
                        bestBlock(best)
                    }

                    statsRow

                    if !session.laps.isEmpty {
                        lapList
                    }
                }
                .padding(Theme.screenPadding)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.surface)
        .preferredColorScheme(.dark)
    }

    // MARK: - Блоки

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ИТОГИ ЗАЕЗДА")
                .font(Theme.label(11))
                .kerning(1.6)
                .foregroundColor(Theme.textTertiary)
            Text(session.trackName)
                .font(Theme.number(24, weight: .black))
                .foregroundColor(.white)
                .lineLimit(2)
            Text(Fmt.shortDate(session.date))
                .font(Theme.body(12))
                .foregroundColor(Theme.textTertiary)
        }
    }

    private func bestBlock(_ best: TimeInterval) -> some View {
        VStack(spacing: 8) {
            Text("ЛУЧШИЙ КРУГ")
                .font(Theme.label(10))
                .kerning(1.4)
                .foregroundColor(Theme.textTertiary)

            Text(Fmt.lap(best))
                .font(Theme.timer(52))
                .foregroundColor(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            deltaBadge(best)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }

    private func deltaBadge(_ best: TimeInterval) -> some View {
        Group {
            if let trackID = session.trackID,
               let record = records.record(for: trackID),
               record.bestLap < best {
                Text("рекорд сейчас: \(Fmt.lap(record.bestLap))")
                    .font(Theme.label(10))
                    .kerning(0.6)
                    .foregroundColor(Theme.positive)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.positive.opacity(0.14)))
            } else {
                Text("новый личный рекорд")
                    .font(Theme.label(10))
                    .kerning(0.6)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.accent.opacity(0.25)))
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            LabeledValue(label: "кругов", value: "\(session.laps.count)")
            Spacer(minLength: 6)
            LabeledValue(label: "средний", value: session.average.map(Fmt.lap) ?? "—")
            Spacer(minLength: 6)
            LabeledValue(label: "сумма", value: totalText, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }

    private var totalText: String {
        let total = session.laps.reduce(0) { $0 + $1.time }
        let minutes = Int(total) / 60
        let seconds = Int(total) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var lapList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("КРУГИ")
                .font(Theme.label(11))
                .kerning(1.6)
                .foregroundColor(Theme.textTertiary)

            VStack(spacing: 0) {
                ForEach(Array(session.laps.enumerated()), id: \.element.id) { index, lap in
                    LapRow(lap: lap, isBest: lap.time == session.best)
                    if index < session.laps.count - 1 {
                        Divider()
                            .background(Theme.stroke)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
        }
    }
}

// MARK: - Строка круга

private struct LapRow: View {
    let lap: Lap
    let isBest: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(lap.index)")
                .font(Theme.number(14, weight: .bold))
                .foregroundColor(Theme.textTertiary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Theme.background))

            Text(Fmt.lap(lap.time))
                .font(Theme.number(17, weight: .heavy))
                .foregroundColor(isBest ? Theme.positive : .white)
                .monospacedDigit()

            Spacer()

            if isBest {
                Text("BEST")
                    .font(Theme.label(9))
                    .kerning(1)
                    .foregroundColor(Theme.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.positive))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Grabber

struct Grabber: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.white.opacity(0.22))
            .frame(width: 38, height: 5)
            .frame(maxWidth: .infinity)
    }
}
