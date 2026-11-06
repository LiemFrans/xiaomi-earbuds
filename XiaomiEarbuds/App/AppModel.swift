import Foundation

/// Owns the app's view models so they exist — and start monitoring — from
/// launch, independent of whether any window has been opened.
@MainActor
final class AppModel {
    static let shared = AppModel()

    let deviceVM = DeviceViewModel()
    let noiseControlVM = NoiseControlViewModel()
    let audioVM = AudioViewModel()
    let spatialAudioVM = SpatialAudioViewModel()
    let gestureVM = GestureViewModel()
    let settingsVM = SettingsViewModel()

    private var hasStarted = false

    private init() {}

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        deviceVM.configureFeatureViewModels(
            noiseControl: noiseControlVM,
            audio: audioVM,
            spatialAudio: spatialAudioVM,
            gesture: gestureVM,
            settings: settingsVM
        )

        deviceVM.startMonitoring()

        Task { await deviceVM.connect() }
    }
}
