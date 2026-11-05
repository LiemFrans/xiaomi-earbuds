import SwiftUI

/// Battery state of one component. `level` is `nil` when the firmware reports
/// it as unknown (e.g. the case while the buds are out of it).
struct BatteryLevel: Sendable, Equatable {
    var level: Int?
    var isCharging: Bool = false

    static let unknown = BatteryLevel(level: nil)
}

struct BatteryInfo: Sendable, Equatable {
    var left: BatteryLevel
    var right: BatteryLevel
    var batteryCase: BatteryLevel

    init(left: BatteryLevel, right: BatteryLevel, batteryCase: BatteryLevel) {
        self.left = left
        self.right = right
        self.batteryCase = batteryCase
    }

    init(leftLevel: Int, rightLevel: Int, caseLevel: Int) {
        self.init(
            left: BatteryLevel(level: leftLevel),
            right: BatteryLevel(level: rightLevel),
            batteryCase: BatteryLevel(level: caseLevel)
        )
    }

    var leftLevel: Int { left.level ?? 0 }
    var rightLevel: Int { right.level ?? 0 }
    var caseLevel: Int { batteryCase.level ?? 0 }

    var averageLevel: Int {
        let known = [left.level, right.level].compactMap { $0 }
        guard !known.isEmpty else { return 0 }
        return known.reduce(0, +) / known.count
    }

    var batteryColor: Color {
        Color.forBatteryLevel(averageLevel)
    }

    static let full = BatteryInfo(leftLevel: 100, rightLevel: 100, caseLevel: 100)
    static let empty = BatteryInfo(left: .unknown, right: .unknown, batteryCase: .unknown)
    static let mock = BatteryInfo(
        left: BatteryLevel(level: 85),
        right: BatteryLevel(level: 90, isCharging: true),
        batteryCase: BatteryLevel(level: 72)
    )
}
