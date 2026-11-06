import SwiftUI

@MainActor @Observable
final class EarbudDevice {
    var name: String
    var internalName: String = ""
    var isConnected: Bool
    var firmwareVersion: String
    var batteryInfo: BatteryInfo

    init(
        name: String = "Xiaomi Earbuds",
        isConnected: Bool = false,
        firmwareVersion: String = "—",
        batteryInfo: BatteryInfo = .empty
    ) {
        self.name = name
        self.isConnected = isConnected
        self.firmwareVersion = firmwareVersion
        self.batteryInfo = batteryInfo
    }

    static let mock: EarbudDevice = {
        let d = EarbudDevice(
            name: "Xiaomi Earbuds",
            isConnected: true,
            firmwareVersion: "3.2.2.6",
            batteryInfo: .mock
        )
        return d
    }()
}
