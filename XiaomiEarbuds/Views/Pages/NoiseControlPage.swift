import SwiftUI

struct NoiseControlPage: View {
    @Environment(NoiseControlViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm

        Form {
            Section("Active Noise Control") {
                Picker("ANC Mode", selection: Binding(
                    get: { vm.ancMode },
                    set: { vm.selectANCMode($0) }
                )) {
                    ForEach(ANCMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.sfSymbol).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle("Smart Noise Cancellation", isOn: Binding(
                    get: { vm.smartANC },
                    set: { _ in vm.toggleSmartANC() }
                ))
                .accessibilityHint("Automatically adjusts noise cancellation based on environment")
            }

            if vm.ancMode == .noiseCancellation {
                Section("ANC Depth") {
                    DepthSlider(depth: $vm.ancDepth, label: "ANC Depth", onCommit: { vm.commitDepth() })
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Noise Control")
    }
}
