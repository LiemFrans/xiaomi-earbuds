import SwiftUI

struct ConnectionStatusDot: View {
    let isConnected: Bool

    @State private var isPulsing = false

    private var statusColor: Color {
        isConnected ? ColorTokens.statusConnected : ColorTokens.statusDisconnected
    }

    private var statusText: String {
        isConnected ? "Connected" : "Disconnected"
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(statusColor)
                .frame(
                    width: Spacing.Component.statusDotSize,
                    height: Spacing.Component.statusDotSize
                )
                .shadow(
                    color: isConnected ? statusColor.opacity(0.5) : .clear,
                    radius: isPulsing ? 4 : 0
                )
                .animation(
                    isConnected
                        ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                        : .default,
                    value: isPulsing
                )

            Text(statusText)
                .font(TypographyTokens.callout)
                .foregroundStyle(
                    isConnected ? ColorTokens.labelPrimary : ColorTokens.labelSecondary
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Connection status")
        .accessibilityValue(statusText)
        .onAppear {
            isPulsing = isConnected
        }
        .onChange(of: isConnected) { _, newValue in
            isPulsing = newValue
        }
    }
}
