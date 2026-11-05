import SwiftUI

struct AudioPage: View {
    @Environment(AudioViewModel.self) private var vm

    var body: some View {
        Form {
            Section {
                Toggle("Adaptive Sound", isOn: Binding(
                    get: { vm.adaptiveSound },
                    set: { _ in vm.toggleAdaptiveSound() }
                ))
                .accessibilityHint("Automatically adjusts audio based on ambient noise")
            }

            Section {
                Toggle("Low Latency Mode", isOn: Binding(
                    get: { vm.lowLatency },
                    set: { _ in vm.toggleLowLatency() }
                ))
                .accessibilityHint("Reduces audio delay for gaming")
            }

            Section("Sound Mode") {
                Picker("Sound Mode", selection: Binding(
                    get: { vm.soundMode },
                    set: { vm.selectSoundMode($0) }
                )) {
                    ForEach(SoundMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Audio Codec") {
                LabeledContent("Current Codec") {
                    Text(vm.codec.displayName).foregroundStyle(.secondary)
                }
                Text("Audio codec is controlled by macOS Bluetooth settings.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Audio")
    }
}
