import SwiftUI

// MARK: - Design tokens
//
// Единая точка правды для цветов, отступов и шрифтов.
// Все экраны используют только эти значения, чтобы приложение выглядело цельно.

enum Theme {
    // MARK: Colors
    static let background = Color(hex: 0x08080A)
    static let surface = Color(hex: 0x131318)
    static let surfaceElevated = Color(hex: 0x1C1C23)
    static let stroke = Color.white.opacity(0.08)
    static let strokeStrong = Color.white.opacity(0.16)

    static let accent = Color(hex: 0xFF2E3A)
    static let accentDark = Color(hex: 0xB3151F)
    static let accentGlow = Color(hex: 0xFF2E3A).opacity(0.35)

    static let positive = Color(hex: 0x32D74B)
    static let negative = Color(hex: 0xFF453A)
    static let warning = Color(hex: 0xFFD60A)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.36)

    // MARK: Metrics
    static let cardRadius: CGFloat = 22
    static let controlRadius: CGFloat = 16
    static let screenPadding: CGFloat = 20
    static let tightSpacing: CGFloat = 8

    // MARK: Typography
    static func timer(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func number(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Мелкий разрядный заголовок: "СКОРОСТЬ", "ЛУЧШИЙ КРУГ" и т. п.
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func body(_ size: CGFloat = 15, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
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
            RadialGradient(
                gradient: Gradient(colors: [Theme.accent.opacity(0.20), Color.clear]),
                center: .init(x: 0.5, y: 0.05),
                startRadius: 8,
                endRadius: 460
            )
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.55)]),
                startPoint: .center,
                endPoint: .bottom
            )
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
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}

struct GlassBackground: View {
    var cornerRadius: CGFloat = Theme.cardRadius

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.number(17, weight: .heavy))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.number(17, weight: .heavy))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Круглая кнопка поверх карты (закрыть, центрировать, звук).
struct MapControlButton: View {
    let icon: String
    var tint: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 44, height: 44)
                .background(GlassBackground(cornerRadius: 22))
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
                .font(Theme.number(17, weight: .heavy))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

struct Badge: View {
    let text: String
    var icon: String?
    var tint: Color = Theme.textSecondary

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon).font(.system(size: 10, weight: .bold))
            }
            Text(text).font(Theme.label(10)).kerning(0.4)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(Color.white.opacity(0.07))
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
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Theme.textTertiary)
            Text(title)
                .font(Theme.number(19, weight: .bold))
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
