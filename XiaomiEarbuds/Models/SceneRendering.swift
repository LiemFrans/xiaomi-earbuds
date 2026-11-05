import Foundation

enum SceneRendering: String, CaseIterable, Identifiable, Sendable, Codable {
    case standard
    case music
    case videos
    case games
    case audiobooks

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: "Standard"
        case .music: "Music"
        case .videos: "Videos"
        case .games: "Games"
        case .audiobooks: "Audiobooks"
        }
    }

    var sfSymbol: String {
        switch self {
        case .standard: "waveform"
        case .music: "music.note"
        case .videos: "film"
        case .games: "gamecontroller"
        case .audiobooks: "book"
        }
    }
}
