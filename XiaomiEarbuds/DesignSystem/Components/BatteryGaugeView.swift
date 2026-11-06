import SwiftUI

struct BatteryGaugeView: View {
    let label: String
    /// `nil` when the firmware cannot report this component right now.
    let level: Int?
    let isCharging: Bool
    let systemImage: String

    init(label: String, level: Int?, isCharging: Bool = false, systemImage: String = "battery.100percent") {
        self.label = label
        self.level = level.map { max(0, min(100, $0)) }
        self.isCharging = isCharging
        self.systemImage = systemImage
    }

    private var isUnknown: Bool { level == nil }

    private var batteryColor: Color {
        isUnknown ? .secondary : ColorTokens.batteryColor(for: level ?? 0)
    }

    var body: some View {
        HStack(spacing: 6) {
            Label {
                Text(label).font(.caption)
            } icon: {
                Image(systemName: systemImage).font(.caption2)
            }
            .foregroundStyle(.secondary)
            .frame(width: 60, alignment: .leading)

            ProgressView(value: Double(level ?? 0), total: 100)
                .tint(batteryColor)
                .progressViewStyle(.linear)
                .opacity(isUnknown ? 0.3 : 1)

            if isCharging && !isUnknown {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                    .frame(width: 12)
            }

            Text(isUnknown ? "—" : "\(level ?? 0)%")
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(batteryColor)
                .frame(width: 34, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            isUnknown
                ? "\(label), unknown"
                : "\(label), \(level ?? 0) percent\(isCharging ? ", charging" : "")"
        )
    }
}
