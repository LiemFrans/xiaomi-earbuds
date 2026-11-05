import SwiftUI

struct BatteryGaugeView: View {
    let label: String
    let level: Int
    let isCharging: Bool
    let systemImage: String

    init(label: String, level: Int, isCharging: Bool = false, systemImage: String = "battery.100percent") {
        self.label = label
        self.level = max(0, min(100, level))
        self.isCharging = isCharging
        self.systemImage = systemImage
    }

    private var batteryColor: Color {
        ColorTokens.batteryColor(for: level)
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

            ProgressView(value: Double(level), total: 100)
                .tint(batteryColor)
                .progressViewStyle(.linear)

            if isCharging {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                    .frame(width: 12)
            }

            Text("\(level)%")
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(batteryColor)
                .frame(width: 34, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(level) percent\(isCharging ? ", charging" : "")")
    }
}
