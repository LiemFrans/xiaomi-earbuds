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
                .task { await autoConnect() }
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

    private func autoConnect() async {
        deviceVM.configureFeatureViewModels(
            noiseControl: noiseControlVM,
            audio: audioVM,
            spatialAudio: spatialAudioVM,
            gesture: gestureVM,
            settings: settingsVM
        )

        await deviceVM.connect()

        guard deviceVM.isConnected, let proto = deviceVM.protocol_ else { return }

        // Inject the live protocol into all feature VMs
        noiseControlVM.configure(protocol: proto)
        audioVM.configure(protocol: proto)
        spatialAudioVM.configure(protocol: proto)
        gestureVM.configure(protocol: proto)
        settingsVM.configure(protocol: proto)

        // Load state concurrently
        async let nc: () = noiseControlVM.loadFromDevice()
        async let au: () = audioVM.loadFromDevice()
        async let ge: () = gestureVM.loadFromDevice()
        async let se: () = settingsVM.loadFromDevice()
        _ = await (nc, au, ge, se)
    }
}
