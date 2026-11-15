import SwiftUI

struct HUDView: View {
    let current: TimeInterval
    let last: TimeInterval?
    let best: TimeInterval?
    let laps: Int
    let speedKph: Double

    var body: some View {
        VStack(spacing: 16) {
            // Верхняя часть: Время и Скорость
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ТЕКУЩИЙ КРУГ")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.gray)
                    Text(Fmt.lap(current))
                        .font(.system(size: 58, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .blue.opacity(0.8), radius: 10, x: 0, y: 0) // Неоновое свечение
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("СКОРОСТЬ")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.gray)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(Fmt.speed(speedKph))
                            .font(.system(size: 58, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                        Text("км/ч")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Разделитель
            Rectangle()
                .fill(LinearGradient(colors: [.clear, .gray.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
            
            // Нижняя часть: Лучший, Прошлый, Круги
            HStack {
                metric(title: "ЛУЧШИЙ", value: best.map(Fmt.lap) ?? "--:--.---", color: .green)
                Spacer()
                metric(title: "ПРОШЛЫЙ", value: last.map(Fmt.lap) ?? "--:--.---", color: .orange)
                Spacer()
                metric(title: "КРУГОВ", value: "\(laps)", color: .white)
            }
        }
        .padding(24)
        // Карбоновый фон с обводкой
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.1)) // Почти черный
                RoundedRectangle(cornerRadius: 24)
                    .stroke(LinearGradient(colors: [.gray.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            }
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }

    private func metric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.4), radius: 5, x: 0, y: 0)
        }
    }
}
