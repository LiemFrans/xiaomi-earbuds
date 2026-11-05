import Foundation
import SwiftUI

/// Centralized user preferences backed by `@AppStorage`.
///
/// Usage in SwiftUI views:
/// ```swift
/// @StateObject private var settings = AppSettings()
/// ```
final class AppSettings: ObservableObject {

    // MARK: - Connection

    /// Bluetooth address of the last successfully connected device.
    @AppStorage("lastConnectedDeviceAddress")
    var lastConnectedDeviceAddress: String = ""

    /// Whether the app should auto-reconnect to the last device on launch.
    @AppStorage("autoReconnect")
    var autoReconnect: Bool = true

    // MARK: - Audio

    /// Last selected audio codec (raw value string of `AudioCodec`).
    @AppStorage("selectedCodec")
    var selectedCodecRaw: String = AudioCodec.ldac.rawValue

    /// Typed accessor for the selected audio codec.
    var selectedCodec: AudioCodec {
        get { AudioCodec(rawValue: selectedCodecRaw) ?? .ldac }
        set { selectedCodecRaw = newValue.rawValue }
    }

    /// Last selected ANC mode (raw value string of `ANCMode`).
    @AppStorage("selectedANCMode")
    var selectedANCModeRaw: String = ANCMode.off.rawValue

    /// Typed accessor for the selected ANC mode.
    var selectedANCMode: ANCMode {
        get { ANCMode(rawValue: selectedANCModeRaw) ?? .off }
        set { selectedANCModeRaw = newValue.rawValue }
    }

    /// Last selected sound mode (raw value string of `SoundMode`).
    @AppStorage("selectedSoundMode")
    var selectedSoundModeRaw: String = SoundMode.balanced.rawValue

    /// Typed accessor for the selected sound mode.
    var selectedSoundMode: SoundMode {
        get { SoundMode(rawValue: selectedSoundModeRaw) ?? .balanced }
        set { selectedSoundModeRaw = newValue.rawValue }
    }

    // MARK: - Features

    /// Whether in-ear detection is enabled.
    @AppStorage("inEarDetectionEnabled")
    var inEarDetectionEnabled: Bool = true

    /// Whether spatial audio is enabled.
    @AppStorage("spatialAudioEnabled")
    var spatialAudioEnabled: Bool = false

    /// Whether dual-device connection is enabled.
    @AppStorage("dualConnectionEnabled")
    var dualConnectionEnabled: Bool = false

    // MARK: - Appearance

    /// Selected UI theme: "system", "light", or "dark".
    @AppStorage("selectedTheme")
    var selectedTheme: String = "system"

    /// Whether the app has completed the initial onboarding flow.
    @AppStorage("hasCompletedOnboarding")
    var hasCompletedOnboarding: Bool = false
}
