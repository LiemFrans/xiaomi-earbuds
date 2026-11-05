import SwiftUI

struct QuickBatteryView: View {
    @Environment(DeviceViewModel.self) private var deviceVM

    var body: some View {
        let b = deviceVM.device.batteryInfo
        VStack(spacing: 4) {
            BatteryGaugeView(label: "Left", level: b.leftLevel, isCharging: b.left.isCharging, systemImage: "earbud.left")
            BatteryGaugeView(label: "Right", level: b.rightLevel, isCharging: b.right.isCharging, systemImage: "earbud.right")
            BatteryGaugeView(label: "Case", level: b.caseLevel, isCharging: b.batteryCase.isCharging, systemImage: "earbuds.case")
        }
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}
