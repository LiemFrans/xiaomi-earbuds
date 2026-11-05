import SwiftUI

struct SettingToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(TypographyTokens.headlineBold)
                    .foregroundStyle(ColorTokens.labelPrimary)

                Text(description)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.labelSecondary)
                    .lineLimit(2)
            }
        }
        .accessibilityLabel(title)
        .accessibilityHint(description)
    }
}
