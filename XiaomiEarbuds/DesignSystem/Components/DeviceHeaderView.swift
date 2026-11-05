import SwiftUI

struct DeviceHeaderView: View {
    var deviceName: String = "REDMI Buds 8 Pro"
    var imageName: String = "headphones"
    var showDolbyBadge: Bool = true

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: imageName)
                .font(.system(size: Spacing.Component.deviceImageSize))
                .foregroundStyle(ColorTokens.accent)
                .accessibilityHidden(true)

            Text(deviceName)
                .font(TypographyTokens.title2)
                .foregroundStyle(ColorTokens.labelPrimary)

            if showDolbyBadge {
                Text("Dolby Audio")
                    .font(TypographyTokens.captionMedium)
                    .foregroundStyle(ColorTokens.labelSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.CornerRadius.small)
                            .fill(ColorTokens.backgroundSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.CornerRadius.small)
                            .strokeBorder(ColorTokens.separator, lineWidth: 0.5)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            showDolbyBadge
                ? "\(deviceName), Dolby Audio supported"
                : deviceName
        )
    }
}
