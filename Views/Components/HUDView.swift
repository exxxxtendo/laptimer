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
            
            // НИЖНЯЯ ПАНЕЛЬ (Используем GeometryReader для ровных 50/50)
            GeometryReader { geo in
                let halfWidth = (geo.size.width / 2)
                
                VStack(spacing: 0) {
                    // Верхняя линия панели
                    Divider().background(Color(white: 0.3))
                    
                    HStack(spacing: 0) {
                        // Ячейка Время
                        VStack(alignment: .leading, spacing: 2) {
                            Text("time").font(.system(size: 22, weight: .heavy, design: .rounded)).italic()
                            Text(Fmt.lap(current)).font(.system(size: 38, weight: .black, design: .rounded)).lineLimit(1).minimumScaleFactor(0.5)
                        }
                        .padding(.horizontal, 16)
                        .frame(width: halfWidth, height: 75, alignment: .leading) // Жесткая высота
                        .background(Color.black)
                        
                        // Вертикальный разделитель
                        Divider().background(Color(white: 0.3))
                        
                        // Ячейка Дельта
                        VStack(alignment: .leading, spacing: 2) {
                            Text("delta").font(.system(size: 22, weight: .heavy, design: .rounded)).italic()
                            Text(deltaString).font(.system(size: 38, weight: .black, design: .rounded)).foregroundColor(deltaColor).lineLimit(1).minimumScaleFactor(0.5)
                        }
                        .padding(.horizontal, 16)
                        .frame(width: halfWidth, height: 75, alignment: .leading)
                        .background(Color.black)
                    }
                    
                    // Горизонтальный разделитель
                    Divider().background(Color(white: 0.3))
                    
                    HStack(spacing: 0) {
                        // Ячейка Прошлый
                        Text("last: \(last.map(Fmt.lap) ?? "--")")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .frame(width: halfWidth, height: 44, alignment: .leading)
                            .background(Color.black)
                        
                        // Вертикальный разделитель
                        Divider().background(Color(white: 0.3))
                        
                        // Ячейка Лучший
                        Text("best: \(best.map(Fmt.lap) ?? "--")")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .frame(width: halfWidth, height: 44, alignment: .leading)
                            .background(Color.black)
                    }
                }
                // Задаем общую высоту панели: 75 + 44 + 2 разделителя = ~121
                .frame(height: 121)
            }
            .frame(height: 121) // Жесткий размер для GeometryReader
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
