import Foundation

enum AudioCodec: String, CaseIterable, Identifiable, Sendable, Codable {
    case ldac
    case aac
    case sbc

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ldac: "LDAC"
        case .aac: "AAC"
        case .sbc: "SBC"
        }
    }

    var label: String { displayName }

    var description: String {
        switch self {
        case .ldac: "High sound quality (CD level) | 96.0 kHz"
        case .aac: "Good sound quality | 48.0 kHz"
        case .sbc: "Standard sound quality | 44.1 kHz"
        }
    }

}
