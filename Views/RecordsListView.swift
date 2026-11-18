import SwiftUI

/// Рекорды по трассам и последние заезды.
struct RecordsListView: View {
    @EnvironmentObject private var records: RecordsStore
    @Environment(\.dismiss) private var dismiss

    @State private var showClearConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        recordsSection
                        historySection
                    }
                    .padding(Theme.screenPadding)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Очистить все рекорды и историю?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Очистить", role: .destructive) {
                records.clearAll()
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    // MARK: - Рекорды

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("РЕКОРДЫ")
                    .font(Theme.label(10))
                    .kerning(1.4)
                    .foregroundColor(Theme.textTertiary)
                Spacer()
                if !records.records.isEmpty {
                    Button("Очистить") { showClearConfirmation = true }
                        .font(Theme.body(12, weight: .semibold))
                        .foregroundColor(Theme.negative)
                }
            }
            .padding(.top, 4)

            if records.records.isEmpty {
                Panel {
                    EmptyState(
                        icon: "trophy",
                        title: "Рекордов нет",
                        message: "Прокатитесь по трассе — лучший круг появится здесь."
                    )
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(records.records.sorted { $0.bestLap < $1.bestLap }) { record in
                        RecordRow(record: record)
                    }
                }
            }
        }
    }

    // MARK: - История

    private var historySection: some View {
        Group {
            if !records.history.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ПОСЛЕДНИЕ ЗАЕЗДЫ")
                        .font(Theme.label(10))
                        .kerning(1.4)
                        .foregroundColor(Theme.textTertiary)

                    VStack(spacing: 8) {
                        ForEach(records.history.prefix(10)) { session in
                            HistoryRow(session: session)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Строка рекорда

private struct RecordRow: View {
    let record: TrackRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.warning)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.trackName)
                    .font(Theme.body(15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text("\(record.lapCount) кругов")
                        .font(Theme.body(11))
                        .foregroundColor(Theme.textTertiary)
                    if let average = record.averageLap {
                        Text("средний \(Fmt.lap(average))")
                            .font(Theme.body(11))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Fmt.lap(record.bestLap))
                    .font(Theme.number(16, weight: .heavy))
                    .foregroundColor(Theme.positive)
                    .monospacedDigit()
                if let date = record.bestLapDate {
                    Text(Fmt.shortDate(date))
                        .font(Theme.body(10))
                        .foregroundColor(Theme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Строка истории

private struct HistoryRow: View {
    let session: SessionResult

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.trackName)
                    .font(Theme.body(14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(Fmt.shortDate(session.date))
                    .font(Theme.body(11))
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                if let best = session.best {
                    Text(Fmt.lap(best))
                        .font(Theme.number(15, weight: .heavy))
                        .foregroundColor(.white)
                        .monospacedDigit()
                } else {
                    Text("—")
                        .font(Theme.number(15, weight: .heavy))
                        .foregroundColor(Theme.textTertiary)
                }
                Text("\(session.laps.count) кругов")
                    .font(Theme.body(10))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
    }
}
