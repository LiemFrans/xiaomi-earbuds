import Foundation

struct DeviceSettings: Sendable, Equatable {
    var dualConnection: Bool
    var answerCallsAutomatically: Bool

    static let `default` = DeviceSettings(
        dualConnection: true,
        answerCallsAutomatically: false
    )

    static let mock = DeviceSettings.default
}
