import SwiftUI

struct HUDView: View {
    let current: TimeInterval
    let last: TimeInterval?
    let best: TimeInterval?
    let delta: TimeInterval
    let laps: Int
    let speedKph: Double

    var body: some View {
        VStack {
            // Верхняя часть: Скорость
            HStack {
                VStack(alignment: .leading, spacing: -5) {
                    Text("SPEED")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.gray)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(Fmt.speed(speedKph))
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("km/h")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                Spacer()
            }
            .padding(.leading, 20)
            .padding(.top, 60) // Отступ от верхней панели (кнопок закрытия)
            
            Spacer()
            
            // Нижняя панель (Time & Delta)
            HStack(spacing: 0) {
                // Левая часть
                VStack(alignment: .leading, spacing: 4) {
                    Text("time")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .italic()
                        .foregroundColor(.gray)
                    
                    // Уменьшили шрифт и добавили minimumScaleFactor, чтобы не обрезалось
                    Text(Fmt.lap(current))
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text("last: \(last.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.black.opacity(0.9))
                
                // Правая часть
                VStack(alignment: .trailing, spacing: 4) {
                    Text("delta")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .italic()
                        .foregroundColor(.gray)
                    
                    Text(deltaString)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(deltaColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text("best: \(best.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(20)
                .background(Color(white: 0.1).opacity(0.95))
            }
            .frame(height: 130)
        }
    }
    
    private var deltaString: String {
        if best == nil { return "0" }
        let formatted = String(format: "%.2f", abs(delta))
        return delta < 0 ? "-\(formatted)" : "+\(formatted)"
    }
    
    private var deltaColor: Color {
        if best == nil { return .white }
        return delta < 0 ? .green : .red
    }
}
