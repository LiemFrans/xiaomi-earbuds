import Foundation

enum ANCMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case transparency
    case noiseCancellation
    case off

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .transparency: "Transparency"
        case .noiseCancellation: "Noise Cancellation"
        case .off: "Off"
        }
    }

    var label: String { displayName }

    var sfSymbol: String {
        switch self {
        case .transparency: "ear"
        case .noiseCancellation: "ear.trianglebadge.exclamationmark"
        case .off: "ear.badge.waveform"
        }
    }

}
