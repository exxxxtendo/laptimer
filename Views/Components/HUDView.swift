import SwiftUI

struct HUDView: View {
    let current: TimeInterval
    let last: TimeInterval?
    let best: TimeInterval?
    let delta: TimeInterval
    let laps: Int
    let speedKph: Double

    // Цвет линий сетки
    private let lineColor = Color(white: 0.3)

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
                let halfWidth = (geo.size.width / 2)
                
                VStack(spacing: 0) {
                    // Верхний ряд
                    HStack(spacing: 0) {
                        // Ячейка Время
                        VStack(alignment: .leading, spacing: 2) {
                            Text("time")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .italic()
                            Text(Fmt.lap(current))
                                .font(.system(size: 34, weight: .black, design: .rounded)) // Чуть уменьшили базовый размер
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .padding(.horizontal, 16)
                        .frame(width: halfWidth, height: 75, alignment: .leading)
                        .background(Color.black)
                        
                        // Вертикальная линия
                        Rectangle().fill(lineColor).frame(width: 1)
                        
                        // Ячейка Дельта
                        VStack(alignment: .leading, spacing: 2) {
                            Text("delta")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .italic()
                            Text(deltaString)
                                .font(.system(size: 34, weight: .black, design: .rounded)) // Сделали такой же размер, как у Time
                                .foregroundColor(deltaColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .padding(.horizontal, 16)
                        .frame(width: halfWidth, height: 75, alignment: .leading)
                        .background(Color.black)
                    }
                    
                    // Горизонтальная линия
                    Rectangle().fill(lineColor).frame(height: 1)
                    
                    // Нижний ряд
                    HStack(spacing: 0) {
                        // Ячейка Прошлый
                        Text("last: \(last.map(Fmt.lap) ?? "--")")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .frame(width: halfWidth, height: 44, alignment: .leading)
                            .background(Color.black)
                        
                        // Вертикальная линия
                        Rectangle().fill(lineColor).frame(width: 1)
                        
                        // Ячейка Лучший
                        Text("best: \(best.map(Fmt.lap) ?? "--")")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .frame(width: halfWidth, height: 44, alignment: .leading)
                            .background(Color.black)
                    }
                }
                // Жесткая высота: 75 + 75? Нет, 75 (верх) + 1 (линия) + 44 (низ) = 120
                .frame(height: 120)
            }
            .frame(height: 120)
            // Добавляем обводку вокруг всей панели, чтобы не было "прозрачных" краев
            .overlay(
                Rectangle()
                    .stroke(lineColor, lineWidth: 1)
            )
        }
        .foregroundColor(.white)
        .background(Color.black) // Гарантируем черный фон для всего HUD
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
