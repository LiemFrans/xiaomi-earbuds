import SwiftUI

// MARK: - Sidebar Item

/// Represents each page in the main window sidebar navigation.
enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case overview
    case noiseControl
    case audio
    case spatialAudio
    case gestures
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .overview: "Overview"
        case .noiseControl: "Noise Control"
        case .audio: "Audio"
        case .spatialAudio: "Spatial Audio"
        case .gestures: "Gestures"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .overview: "headphones"
        case .noiseControl: "ear.trianglebadge.exclamationmark"
        case .audio: "speaker.wave.3"
        case .spatialAudio: "globe"
        case .gestures: "hand.tap"
        case .settings: "gear"
        }
    }
}

// MARK: - Content Router

/// Routes the selected sidebar item to the corresponding detail page view.
struct ContentRouter: View {
    let selection: SidebarItem

    var body: some View {
        switch selection {
        case .overview:
            OverviewPage()
        case .noiseControl:
            NoiseControlPage()
        case .audio:
            AudioPage()
        case .spatialAudio:
            SpatialAudioPage()
        case .gestures:
            GesturesPage()
        case .settings:
            SettingsPage()
        }
    }
}

// MARK: - Preview
