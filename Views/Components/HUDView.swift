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
            
            // НИЖНЯЯ СЕТКА 2x2 (Идеальные 1px линии)
            VStack(spacing: 0) {
                // Верхний ряд
                HStack(spacing: 0) {
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black)
                    
                    // Вертикальная линия
                    Rectangle()
                        .fill(Color(white: 0.3))
                        .frame(width: 1)
                    
                    // Ячейка 2: Дельта
                    VStack(alignment: .leading, spacing: 2) { // <--- Выравнивание по левому краю
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading) // <--- Выравнивание по левому краю
                    .background(Color.black)
                }
                
                // Горизонтальная линия
                Rectangle()
                    .fill(Color(white: 0.3))
                    .frame(height: 1)
                
                // Нижний ряд
                HStack(spacing: 0) {
                    // Ячейка 3: Прошлый
                    Text("last: \(last.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black)
                    
                    // Вертикальная линия
                    Rectangle()
                        .fill(Color(white: 0.3))
                        .frame(width: 1)
                    
                    // Ячейка 4: Лучший
                    Text("best: \(best.map(Fmt.lap) ?? "--")")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading) // <--- Выравнивание по левому краю
                        .background(Color.black)
                }
            }
            // Верхняя граница всей таблицы (чтобы отделить от карты)
            .overlay(
                Rectangle()
                    .fill(Color(white: 0.3))
                    .frame(height: 1),
                alignment: .top
            )
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
