import Foundation

enum GestureAction: String, CaseIterable, Identifiable, Sendable, Codable {
    case none
    case playPause
    case previousSong
    case nextSong
    case volumeUp
    case volumeDown
    case noiseControl
    case voiceAssistant
    case adjustVolume

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "None"
        case .playPause: "Play / Pause"
        case .previousSong: "Previous Song"
        case .nextSong: "Next Song"
        case .volumeUp: "Volume Up"
        case .volumeDown: "Volume Down"
        case .noiseControl: "Noise Control"
        case .voiceAssistant: "Voice Assistant"
        case .adjustVolume: "Adjust Volume"
        }
    }

    var sfSymbol: String {
        switch self {
        case .none: "xmark.circle"
        case .playPause: "playpause"
        case .previousSong: "backward.end"
        case .nextSong: "forward.end"
        case .volumeUp: "speaker.plus"
        case .volumeDown: "speaker.minus"
        case .noiseControl: "ear.trianglebadge.exclamationmark"
        case .voiceAssistant: "mic"
        case .adjustVolume: "speaker.wave.2"
        }
    }
}

/// Gesture kinds and their wire ids in config 2 (`[type, left, right]` triples).
enum GestureType: UInt8, CaseIterable, Identifiable, Sendable {
    case single = 0x04
    case double = 0x01
    case triple = 0x02
    case pressHold = 0x03
    case swipe = 0x05

    var id: UInt8 { rawValue }

    var displayName: String {
        switch self {
        case .single: "Single Press"
        case .double: "Double Press"
        case .triple: "Triple Press"
        case .pressHold: "Press & Hold"
        case .swipe: "Swipe"
        }
    }

    var sfSymbol: String {
        switch self {
        case .single: "hand.point.up.left"
        case .double: "hand.tap"
        case .triple: "hand.tap.fill"
        case .pressHold: "hand.raised"
        case .swipe: "hand.draw"
        }
    }

    /// Actions the REDMI Buds 8 Pro firmware accepts for this gesture kind.
    var supportedActions: [GestureAction] {
        switch self {
        case .single, .triple:
            [.none, .playPause, .previousSong, .nextSong, .volumeUp, .volumeDown]
        case .double:
            [.playPause, .previousSong, .nextSong, .volumeUp, .volumeDown]
        case .pressHold:
            [.noiseControl, .voiceAssistant]
        case .swipe:
            [.none, .adjustVolume]
        }
    }
}
