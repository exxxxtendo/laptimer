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
            
            // СЕТКА (используем трюк с серым фоном для идеальных линий 1px)
            VStack(spacing: 1) {
                // Верхняя линия
                Rectangle().fill(Color(white: 0.3)).frame(height: 1)
                
                // Верхний ряд
                HStack(spacing: 1) {
                    // Время
                    VStack(alignment: .leading, spacing: 2) {
                        Text("time").font(.system(size: 22, weight: .heavy, design: .rounded)).italic()
                        Text(Fmt.lap(current)).font(.system(size: 36, weight: .black, design: .rounded)).lineLimit(1).minimumScaleFactor(0.5)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black)
                    
                    // Дельта
                    VStack(alignment: .leading, spacing: 2) {
                        Text("delta").font(.system(size: 22, weight: .heavy, design: .rounded)).italic()
                        Text(deltaString).font(.system(size: 36, weight: .black, design: .rounded)).foregroundColor(deltaColor).lineLimit(1).minimumScaleFactor(0.5)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black)
                }
                
                // Разделительная линия
                Rectangle().fill(Color(white: 0.3)).frame(height: 1)
                
                // Нижний ряд
                HStack(spacing: 1) {
                    // Прошлый
                    Text("last: \(last.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black)
                    
                    // Лучший
                    Text("best: \(best.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black)
                }
            }
            .background(Color(white: 0.3)) // Это создаст вертикальную линию между ячейками
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
