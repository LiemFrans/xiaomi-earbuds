import Foundation

enum SampleRate: String, CaseIterable, Identifiable, Sendable, Codable {
    case khz44_1
    case khz48_0
    case khz96_0

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .khz44_1: "44.1 kHz"
        case .khz48_0: "48.0 kHz"
        case .khz96_0: "96.0 kHz"
        }
    }

    var description: String {
        switch self {
        case .khz44_1: "Standard CD quality"
        case .khz48_0: "Professional audio quality"
        case .khz96_0: "Hi-Res audio quality"
        }
    }
}
