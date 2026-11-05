import SwiftUI

struct MenuBarPopoverView: View {
    @Environment(DeviceViewModel.self) private var deviceVM
    @Environment(NoiseControlViewModel.self) private var ncVM
    @Environment(AudioViewModel.self) private var audioVM

    var body: some View {
        @Bindable var nc = ncVM

        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "headphones").font(.title3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(deviceVM.device.name).font(.headline).lineLimit(1)
                    ConnectionStatusDot(isConnected: deviceVM.isConnected)
                }
                Spacer()
            }
            .padding(12)

            Divider()

            if !deviceVM.isConnected {
                VStack(spacing: 12) {
                    Image(systemName: "headphones")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Disconnected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if deviceVM.connectionState == .connecting {
                        ProgressView().controlSize(.small)
                    } else {
                        Button("Connect") { Task { await deviceVM.connect() } }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            }

            if deviceVM.isConnected {
            // Content
            VStack(alignment: .leading, spacing: 10) {
                // Battery
                QuickBatteryView()

                // ANC
                VStack(alignment: .leading, spacing: 8) {
                    Text("Noise Control").font(.caption.weight(.semibold)).foregroundStyle(.secondary)

                    Picker("ANC", selection: Binding(
                        get: { nc.ancMode },
                        set: { nc.selectANCMode($0) }
                    )) {
                        ForEach(ANCMode.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if nc.ancMode == .noiseCancellation {
                        HStack(spacing: 4) {
                            Text("Light").font(.caption2).foregroundStyle(.tertiary)
                            Slider(value: $nc.ancDepth, in: 0...1, onEditingChanged: { if !$0 { nc.commitDepth() } })
                                .controlSize(.small)
                            Text("Deep").font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))

                // Sound
                HStack {
                    Text("Sound Mode").font(.caption)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { audioVM.soundMode },
                        set: { audioVM.selectSoundMode($0) }
                    )) {
                        ForEach(SoundMode.allCases) { Text($0.displayName).tag($0) }
                    }
                    .labelsHidden().pickerStyle(.menu).controlSize(.small)
                }
                .padding(.horizontal, 4)

                HStack {
                    Text("Codec").font(.caption)
                    Spacer()
                    Text(audioVM.codec.displayName).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
            .padding(12)
            } // end if connected
        }
        .frame(width: 280)
        .fixedSize()
    }
}
