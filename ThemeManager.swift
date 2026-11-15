import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case raceChrono = "RaceChrono"
    case standard = "Обычный"
    case modern = "Современный"
    
    var id: String { self.rawValue }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .modern
}
