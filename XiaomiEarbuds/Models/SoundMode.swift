import Foundation

enum SoundMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case balanced
    case enhancedBass
    case enhancedVoice
    case enhancedTreble
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .balanced: "Balanced"
        case .enhancedBass: "Enhanced Bass"
        case .enhancedVoice: "Enhanced Voice"
        case .enhancedTreble: "Enhanced Treble"
        case .custom: "Custom"
        }
    }

    var label: String { displayName }

    var sfSymbol: String {
        switch self {
        case .balanced: "slider.horizontal.3"
        case .enhancedBass: "speaker.wave.3"
        case .enhancedVoice: "person.wave.2"
        case .enhancedTreble: "waveform"
        case .custom: "slider.vertical.3"
        }
    }

}
