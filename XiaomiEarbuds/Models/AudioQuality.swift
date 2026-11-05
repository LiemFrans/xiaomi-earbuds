import Foundation

enum AudioQuality: String, CaseIterable, Identifiable, Sendable, Codable {
    case xiaomiDimensional
    case dolbyAudio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .xiaomiDimensional: "Xiaomi Dimensional"
        case .dolbyAudio: "Dolby Audio"
        }
    }

    var description: String {
        switch self {
        case .xiaomiDimensional: "Xiaomi proprietary spatial audio engine"
        case .dolbyAudio: "Dolby Atmos immersive audio experience"
        }
    }
}
