import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case ios = "iOS (Стекло)"
    case raceChrono = "RaceChrono"
    case modern = "Современный (Modern)"
    
    var id: String { self.rawValue }
}

class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var currentTheme: AppTheme = .ios
}
