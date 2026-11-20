import SwiftUI

// MARK: - GTA VI inspired design tokens
//
// Кислотно-розовая палитра: неоновый малиновый, тёплый персиковый акцент,
// глубокий фиолетово-чёрный фон, толстые «ретро-плакатные» шрифты.

enum Theme {
    // MARK: Core colors
    static let background = Color(hex: 0x12000E)
    static let surface = Color(hex: 0x1E0419)
    static let surfaceElevated = Color(hex: 0x2C0725)
    static let stroke = Color(hex: 0xFF4FA3).opacity(0.22)
    static let strokeStrong = Color(hex: 0xFF4FA3).opacity(0.55)

    /// Главный кислотно-розовый.
    static let accent = Color(hex: 0xFF1E7A)
    /// Более «закатный» розово-оранжевый — для акцентов и градиентов.
    static let accentWarm = Color(hex: 0xFF6B35)
    /// Лимонно-жёлтый из плакатов GTA.
    static let accentLemon = Color(hex: 0xFFD84D)
    /// Голубой неон — второй акцент.
    static let accentCyan = Color(hex: 0x4DE0FF)
    /// Фиолетовый неон — подложка градиентов.
    static let accentViolet = Color(hex: 0x8B2FFF)

    static let positive = Color(hex: 0x3DFF9E)
    static let negative = Color(hex: 0xFF3B5C)
    static let warning = Color(hex: 0xFFD84D)

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xFFB3D9)
    static let textTertiary = Color(hex: 0xC77FA8)

    // MARK: Metrics
    static let cardRadius: CGFloat = 20
    static let controlRadius: CGFloat = 14
    static let screenPadding: CGFloat = 18
    static let tightSpacing: CGFloat = 8

    // MARK: Typography
    /// Огромные цифры таймера.
    static func timer(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func number(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Разрядный «плакатный» заголовок.
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func body(_ size: CGFloat = 15, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Шрифт с засечками в духе «Vice City» — для логотипа.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }
}

// MARK: - Hex colors

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

// MARK: - Background

struct AppBackground: View {
    var body: some View {
        ZStack {
            Theme.background

            // Верхний малиновый «закат».
            RadialGradient(
                gradient: Gradient(colors: [Theme.accent.opacity(0.42), Color.clear]),
                center: .init(x: 0.5, y: -0.05),
                startRadius: 10,
                endRadius: 520
            )

            // Нижний фиолетовый неон.
            RadialGradient(
                gradient: Gradient(colors: [Theme.accentViolet.opacity(0.35), Color.clear]),
                center: .init(x: 0.9, y: 1.05),
                startRadius: 10,
                endRadius: 480
            )

            // Лёгкие «сканлайны» для ретро-ощущения.
            Scanlines()
                .opacity(0.35)
        }
        .ignoresSafeArea()
    }
}

struct Scanlines: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                var y: CGFloat = 0
                while y < geo.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    y += 3
                }
            }
            .stroke(Color.white.opacity(0.035), lineWidth: 1)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Surfaces

struct Panel<Content: View>: View {
    var cornerRadius: CGFloat = Theme.cardRadius
    var fill: Color = Theme.surface
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.strokeStrong, lineWidth: 1.5)
            )
            .shadow(color: Theme.accent.opacity(0.25), radius: 18, x: 0, y: 0)
    }
}

struct GlassBackground: View {
    var cornerRadius: CGFloat = Theme.cardRadius

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Theme.surface.opacity(0.86))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.strokeStrong, lineWidth: 1.5)
            )
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.number(17, weight: .black))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1.5)
            )
            .shadow(color: color.opacity(0.65), radius: 14, x: 0, y: 0)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.number(17, weight: .black))
            .foregroundColor(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .stroke(Theme.strokeStrong, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Круглая кнопка поверх карты.
struct MapControlButton: View {
    let icon: String
    var tint: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(tint)
                .frame(width: 46, height: 46)
                .background(GlassBackground(cornerRadius: 23))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Small pieces

struct LabeledValue: View {
    let label: String
    let value: String
    var tint: Color = .white
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(label.uppercased())
                .font(Theme.label())
                .foregroundColor(Theme.textTertiary)
                .kerning(0.8)
            Text(value)
                .font(Theme.number(17, weight: .black))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

struct Badge: View {
    let text: String
    var icon: String?
    var tint: Color = Theme.accentLemon

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon).font(.system(size: 9, weight: .black))
            }
            Text(text.uppercased()).font(Theme.label(9)).kerning(0.6)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(tint.opacity(0.16))
        )
        .overlay(
            Capsule().stroke(tint.opacity(0.45), lineWidth: 1)
        )
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .black))
                .foregroundColor(Theme.accent)
                .shadow(color: Theme.accent.opacity(0.8), radius: 12)
            Text(title)
                .font(Theme.number(19, weight: .black))
                .foregroundColor(Theme.textPrimary)
            Text(message)
                .font(Theme.body(14))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - GTA-style section header

struct NeonHeading: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Theme.accent)
                .frame(width: 4, height: 14)
                .shadow(color: Theme.accent, radius: 6)
            Text(text.uppercased())
                .font(Theme.label(11))
                .kerning(2.2)
                .foregroundColor(Theme.accentLemon)
            Spacer()
        }
    }
}
