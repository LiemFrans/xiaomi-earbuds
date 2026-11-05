import Foundation

/// Left/right action binding for one gesture type.
struct GestureBinding: Sendable, Equatable {
    var left: GestureAction
    var right: GestureAction
}

struct GestureConfig: Sendable, Equatable {
    var bindings: [GestureType: GestureBinding]

    subscript(type: GestureType) -> GestureBinding {
        get { bindings[type] ?? GestureConfig.default.bindings[type]! }
        set { bindings[type] = newValue }
    }

    /// Defaults as reported by a factory REDMI Buds 8 Pro (config 2).
    static let `default` = GestureConfig(bindings: [
        .single: GestureBinding(left: .none, right: .none),
        .double: GestureBinding(left: .playPause, right: .playPause),
        .triple: GestureBinding(left: .nextSong, right: .nextSong),
        .pressHold: GestureBinding(left: .noiseControl, right: .noiseControl),
        .swipe: GestureBinding(left: .adjustVolume, right: .adjustVolume),
    ])

    static let mock = GestureConfig.default
}
