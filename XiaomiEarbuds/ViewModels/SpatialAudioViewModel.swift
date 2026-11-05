import Foundation
import os.log

/// Spatial audio features are not controllable via RCSP on the REDMI Buds 8 Pro.
/// This ViewModel provides local toggles for the UI but does not send commands.
@MainActor @Observable
final class SpatialAudioViewModel {
    var immersiveSound: Bool
    var audioQuality: AudioQuality
    var headTracking: Bool
    var sceneRendering: SceneRendering

    private let logger = Logger(subsystem: "com.xiaomi.earbuds", category: "SpatialAudioVM")

    init(
        immersiveSound: Bool = false,
        audioQuality: AudioQuality = .xiaomiDimensional,
        headTracking: Bool = false,
        sceneRendering: SceneRendering = .standard
    ) {
        self.immersiveSound = immersiveSound
        self.audioQuality = audioQuality
        self.headTracking = headTracking
        self.sceneRendering = sceneRendering
    }

    func configure(protocol proto: XiaomiProtocol) {
        // Spatial audio is not controllable via RCSP on this model.
    }

    func loadFromDevice() async {
        logger.info("Spatial audio is not controllable via RCSP on this device")
    }

    static let preview = SpatialAudioViewModel(immersiveSound: true, headTracking: true, sceneRendering: .music)
}
