import SwiftUI

@main
struct XiaomiEarbudsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private var model: AppModel { AppModel.shared }

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(model.deviceVM)
                .environment(model.noiseControlVM)
                .environment(model.audioVM)
                .environment(model.spatialAudioVM)
                .environment(model.gestureVM)
                .environment(model.settingsVM)
        }
        .defaultSize(width: 780, height: 600)

        MenuBarExtra("Xiaomi Earbuds", systemImage: "headphones") {
            MenuBarPopoverView()
                .environment(model.deviceVM)
                .environment(model.noiseControlVM)
                .environment(model.audioVM)
        }
        .menuBarExtraStyle(.window)
    }
}
