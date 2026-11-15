import SwiftUI

struct HUDView: View {
    let current: TimeInterval
    let last: TimeInterval?
    let best: TimeInterval?
    let delta: TimeInterval
    let laps: Int
    let speedKph: Double

    var body: some View {
        VStack(spacing: 0) {
            // СКОРОСТЬ (слева сверху, без фона)
            HStack {
                Text(Fmt.speed(speedKph))
                    .font(.system(size: 90, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                    .padding(.leading, 20)
                    .padding(.top, 20)
                
                Spacer()
            }
            
            Spacer()
            
            // НИЖНЯЯ ПАНЕЛЬ (черная, разделена пополам)
            HStack(spacing: 0) {
                // Левая половина (Время, Прошлый)
                VStack(alignment: .leading, spacing: 6) {
                    Text("time")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .italic()
                        .foregroundColor(.white)
                    
                    Text(Fmt.lap(current))
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5) // Защита от обрезания текста
                    
                    Text("last: \(last.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.black) // Глухой черный
                
                // Правая половина (Дельта, Лучший)
                VStack(alignment: .trailing, spacing: 6) {
                    Text("delta")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .italic()
                        .foregroundColor(.white)
                    
                    Text(deltaString)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(deltaColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text("best: \(best.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(20)
                .background(Color(white: 0.1)) // Чуть светлее для градиента
            }
            .frame(height: 140)
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
