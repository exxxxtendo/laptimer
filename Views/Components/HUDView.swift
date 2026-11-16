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
            
            // НИЖНЯЯ ПАНЕЛЬ
            GeometryReader { geo in
                let halfWidth = (geo.size.width / 2) - 1 // Вычитаем 1 пиксель под центральную линию
                
                VStack(spacing: 1) { // 1 пиксель между рядами
                    HStack(spacing: 1) { // 1 пиксель между колонками
                        VStack(alignment: .leading, spacing: 2) {
                            Text("time").font(.system(size: 22, weight: .heavy, design: .rounded)).italic()
                            Text(Fmt.lap(current)).font(.system(size: 34, weight: .black, design: .rounded)).lineLimit(1).minimumScaleFactor(0.6)
                        }
                        .padding(.horizontal, 16)
                        .frame(width: halfWidth, height: 75, alignment: .leading)
                        .background(Color.black)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("delta").font(.system(size: 22, weight: .heavy, design: .rounded)).italic()
                            Text(deltaString).font(.system(size: 34, weight: .black, design: .rounded)).foregroundColor(deltaColor).lineLimit(1).minimumScaleFactor(0.6)
                        }
                        .padding(.horizontal, 16)
                        .frame(width: halfWidth, height: 75, alignment: .leading)
                        .background(Color.black)
                    }
                    
                    HStack(spacing: 1) {
                        Text("last: \(last.map(Fmt.lap) ?? "--")")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .frame(width: halfWidth, height: 44, alignment: .leading)
                            .background(Color.black)
                        
                        Text("best: \(best.map(Fmt.lap) ?? "--")")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .frame(width: halfWidth, height: 44, alignment: .leading)
                            .background(Color.black)
                    }
                }
                .background(Color(white: 0.3)) // Этот цвет заполняет все 1px отступы
                .frame(height: 120)
            }
            .frame(height: 120)
            // Рамка вокруг всей панели (чтобы верхняя линия тоже была)
            .overlay(
                Rectangle().stroke(Color(white: 0.3), lineWidth: 1)
            )
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
