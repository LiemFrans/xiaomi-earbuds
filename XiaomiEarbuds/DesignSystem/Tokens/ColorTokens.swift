import SwiftUI

// MARK: - Semantic Colors

enum ColorTokens {

    // MARK: Backgrounds

    static let backgroundPrimary = Color(.windowBackgroundColor)
    static let backgroundSecondary = Color(.controlBackgroundColor)
    static let backgroundTertiary = Color(.underPageBackgroundColor)
    static let backgroundGrouped = Color(.controlBackgroundColor)

    // MARK: Labels

    static let labelPrimary = Color(.labelColor)
    static let labelSecondary = Color(.secondaryLabelColor)
    static let labelTertiary = Color(.tertiaryLabelColor)
    static let labelQuaternary = Color(.quaternaryLabelColor)

    // MARK: Separators

    static let separator = Color(.separatorColor)
    static let gridLine = Color(.gridColor)

    // MARK: Accent

    static let accent = Color.accentColor

    // MARK: Battery

    static let batteryGreen = Color.green
    static let batteryYellow = Color.yellow
    static let batteryRed = Color.red

    static func batteryColor(for level: Int) -> Color {
        switch level {
        case ...10:
            return batteryRed
        case 11...20:
            return batteryYellow
        default:
            return batteryGreen
        }
    }

    // MARK: Status

    static let statusConnected = Color.green
    static let statusDisconnected = Color(.systemGray)

    // MARK: Interactive

    static let controlActive = Color.accentColor
    static let controlDisabled = Color(.disabledControlTextColor)
}

// MARK: - Convenience View Extension

extension Color {
    static let ds = ColorTokens.self
}

@ViewBuilder
private func colorSwatch(_ name: String, _ color: Color) -> some View {
    HStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
        Text(name)
            .font(.callout)
    }
}
