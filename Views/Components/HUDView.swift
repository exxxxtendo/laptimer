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
            // СКОРОСТЬ (слева сверху)
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
            
            // НИЖНЯЯ СЕТКА 2x2 (Тонкие рамки, черный фон)
            VStack(spacing: 1) { // 1 пиксель между строками
                HStack(spacing: 1) { // 1 пиксель между колонками
                    // Ячейка 1: Время
                    VStack(alignment: .leading, spacing: 2) {
                        Text("time")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .italic()
                            .foregroundColor(.white)
                        Text(Fmt.lap(current))
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black)
                    
                    // Ячейка 2: Дельта
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("delta")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .italic()
                            .foregroundColor(.white)
                        Text(deltaString)
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(deltaColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .background(Color.black)
                }
                
                HStack(spacing: 1) {
                    // Ячейка 3: Прошлый
                    Text("last: \(last.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black)
                    
                    // Ячейка 4: Лучший
                    Text("best: \(best.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .background(Color.black)
                }
            }
            .background(Color(white: 0.2)) // Цвет тонких линий сетки
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
