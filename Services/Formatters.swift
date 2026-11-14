import Foundation

enum Fmt {
    static func lap(_ t: TimeInterval) -> String {
        guard t.isFinite, t >= 0 else { return "0:00.000" }
        let m = Int(t) / 60
        let s = Int(t) % 60
        let ms = Int(((t - floor(t)) * 1000).rounded())
        return String(format: "%d:%02d.%03d", m, s, ms)
    }
    static func speed(_ kph: Double) -> String {
        String(format: "%.0f", max(0, kph))
    }
}
