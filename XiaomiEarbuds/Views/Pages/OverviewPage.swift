import SwiftUI

struct OverviewPage: View {
    @Environment(DeviceViewModel.self) private var deviceVM
    @Environment(NoiseControlViewModel.self) private var noiseControlVM
    @Environment(AudioViewModel.self) private var audioVM

    var body: some View {
        @Bindable var ncVM = noiseControlVM

        Form {
            Section { DeviceHeaderView(deviceName: deviceVM.device.name) }

            Section("Battery") {
                let bat = deviceVM.device.batteryInfo
                VStack(spacing: 8) {
                    BatteryGaugeView(label: "Left", level: bat.left.level, isCharging: bat.left.isCharging, systemImage: "earbud.left")
                    BatteryGaugeView(label: "Right", level: bat.right.level, isCharging: bat.right.isCharging, systemImage: "earbud.right")
                    BatteryGaugeView(label: "Case", level: bat.batteryCase.level, isCharging: bat.batteryCase.isCharging, systemImage: "earbuds.case")
                }
                .padding(.vertical, 4)
            }

            Section("Noise Control") {
                Picker("ANC Mode", selection: Binding(
                    get: { ncVM.ancMode },
                    set: { ncVM.selectANCMode($0) }
                )) {
                    ForEach(ANCMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if noiseControlVM.ancMode == .noiseCancellation {
                    DepthSlider(depth: $ncVM.ancDepth, label: "ANC Depth", onCommit: { noiseControlVM.commitDepth() })
                }
            }

            Section("Sound") {
                Picker("Sound Mode", selection: Binding(
                    get: { audioVM.soundMode },
                    set: { audioVM.selectSoundMode($0) }
                )) {
                    ForEach(SoundMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                LabeledContent("Audio Codec") {
                    Text(audioVM.codec.displayName).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Overview")
    }
}
