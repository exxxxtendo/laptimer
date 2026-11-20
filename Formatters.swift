import Foundation

enum Fmt {
    /// 1:02.345 — время круга. Всегда три знака после точки: 0:01.1000 не появится.
    static func lap(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "0:00.000" }
        let totalMilliseconds = Int((time * 1000).rounded())
        let milliseconds = totalMilliseconds % 1000
        let totalSeconds = totalMilliseconds / 1000
        let seconds = totalSeconds % 60
        let minutes = totalSeconds / 60
        return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
    }

    /// 00:42.1 — короткий формат для секундомера.
    static func stopwatch(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "00:00.0" }
        let seconds = Int(time)
        let tenths = Int((time - Double(seconds)) * 10)
        return String(format: "%02d:%02d.%d", seconds / 60, seconds % 60, tenths)
    }

    static func delta(_ value: TimeInterval?) -> String {
        guard let value = value, value.isFinite else { return "—" }
        let text = String(format: "%.2f", abs(value))
        if abs(value) < 0.005 { return "0.00" }
        return value < 0 ? "-\(text)" : "+\(text)"
    }

    static func speed(_ kph: Double) -> String {
        guard kph.isFinite else { return "0" }
        return String(format: "%.0f", max(0, kph))
    }

    static func distance(_ meters: Double) -> String {
        guard meters.isFinite, meters >= 0 else { return "0 м" }
        if meters < 1000 { return String(format: "%.0f м", meters) }
        return String(format: "%.2f км", meters / 1000)
    }

    static func shortDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        return shortDateFormatter.string(from: date)
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter
    }()
}
