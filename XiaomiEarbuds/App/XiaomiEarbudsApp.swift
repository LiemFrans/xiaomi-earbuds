import SwiftUI

@main
struct XiaomiEarbudsApp: App {
    @State private var deviceVM = DeviceViewModel()
    @State private var noiseControlVM = NoiseControlViewModel()
    @State private var audioVM = AudioViewModel()
    @State private var spatialAudioVM = SpatialAudioViewModel()
    @State private var gestureVM = GestureViewModel()
    @State private var settingsVM = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(deviceVM)
                .environment(noiseControlVM)
                .environment(audioVM)
                .environment(spatialAudioVM)
                .environment(gestureVM)
                .environment(settingsVM)
                .task { await setup() }
        }
        .defaultSize(width: 780, height: 600)

        MenuBarExtra("Xiaomi Earbuds", systemImage: "headphones") {
            MenuBarPopoverView()
                .environment(deviceVM)
                .environment(noiseControlVM)
                .environment(audioVM)
        }
        .menuBarExtraStyle(.window)
    }

    private func setup() async {
        deviceVM.configureFeatureViewModels(
            noiseControl: noiseControlVM,
            audio: audioVM,
            spatialAudio: spatialAudioVM,
            gesture: gestureVM,
            settings: settingsVM
        )

        // Start monitoring — auto-connects when earbuds appear on Bluetooth
        deviceVM.startMonitoring()

        // Also try to connect immediately if earbuds are already paired
        await deviceVM.connect()
    }
}
