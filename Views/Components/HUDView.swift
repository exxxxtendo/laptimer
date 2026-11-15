import SwiftUI

struct HUDView: View {
    let current: TimeInterval
    let last: TimeInterval?
    let best: TimeInterval?
    let delta: TimeInterval
    let laps: Int
    let speedKph: Double

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Скорость слева сверху (накладывается на карту)
            Text(Fmt.speed(speedKph))
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.leading, 20)
                .padding(.top, 10)
                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)

            VStack {
                Spacer()
                
                // Нижняя панель
                HStack(spacing: 0) {
                    // Левая часть (Time, Last)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("time")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .italic() // <--- Исправлено тут
                            .foregroundColor(.white)
                        
                        Text(Fmt.lap(current))
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        
                        Text("last: \(last.map(Fmt.lap) ?? "--")")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.black.opacity(0.85))
                    
                    // Правая часть (Delta, Best)
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("delta")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .italic() // <--- Исправлено тут
                            .foregroundColor(.white)
                        
                        Text(deltaString)
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundColor(deltaColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        
                        Text("best: \(best.map(Fmt.lap) ?? "--")")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding()
                    .background(Color(white: 0.1).opacity(0.95)) // Чуть светлее для градиента
                }
                .frame(height: 140)
            }
        }
    }
    
    // Логика отображения Delta
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
