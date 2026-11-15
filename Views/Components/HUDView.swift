import SwiftUI

struct HUDView: View {
    let current: TimeInterval
    let last: TimeInterval?
    let best: TimeInterval?
    let delta: TimeInterval
    let laps: Int
    let speedKph: Double

    // Берем половину ширины экрана минус 1 пиксель (для линии)
    private var halfWidth: CGFloat {
        (UIScreen.main.bounds.width - 1) / 2
    }

    var body: some View {
        VStack(spacing: 0) {
            // СКОРОСТЬ
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
            
            // НИЖНЯЯ СЕТКА (Жестко по 50% ширины)
            VStack(spacing: 0) {
                // Верхний ряд
                HStack(spacing: 0) {
                    // Левая ячейка
                    VStack(alignment: .leading, spacing: 2) {
                        Text("time").font(.system(size: 22, weight: .heavy, design: .rounded)).italic()
                        Text(Fmt.lap(current)).font(.system(size: 36, weight: .black, design: .rounded)).lineLimit(1).minimumScaleFactor(0.5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(width: halfWidth, alignment: .leading)
                    .background(Color.black)
                    
                    // Линия
                    Rectangle().fill(Color(white: 0.3)).frame(width: 1)
                    
                    // Правая ячейка
                    VStack(alignment: .leading, spacing: 2) {
                        Text("delta").font(.system(size: 22, weight: .heavy, design: .rounded)).italic()
                        Text(deltaString).font(.system(size: 36, weight: .black, design: .rounded)).foregroundColor(deltaColor).lineLimit(1).minimumScaleFactor(0.5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(width: halfWidth, alignment: .leading)
                    .background(Color.black)
                }
                
                // Линия
                Rectangle().fill(Color(white: 0.3)).frame(height: 1)
                
                // Нижний ряд
                HStack(spacing: 0) {
                    Text("last: \(last.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .frame(width: halfWidth, alignment: .leading)
                        .background(Color.black)
                    
                    Rectangle().fill(Color(white: 0.3)).frame(width: 1)
                    
                    Text("best: \(best.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .frame(width: halfWidth, alignment: .leading)
                        .background(Color.black)
                }
            }
            .overlay(Rectangle().fill(Color(white: 0.3)).frame(height: 1), alignment: .top) // Верхняя линия
        }
        .foregroundColor(.white)
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
