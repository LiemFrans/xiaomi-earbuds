import SwiftUI
import AppKit

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
                Spacer(minLength: 0)
            }
            .padding(12)

            Divider()

            if !deviceVM.isConnected {
                VStack(spacing: 10) {
                    if deviceVM.isBluetoothPermissionDenied {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.orange)
                        Text("Bluetooth permission needed")
                            .font(.subheadline.weight(.medium))
                        Text("Allow Xiaomi Earbuds in System Settings → Privacy & Security → Bluetooth, then try again.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("Open System Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                    } else {
                        Image(systemName: "headphones").font(.system(size: 32)).foregroundStyle(.tertiary)
                        Text(deviceVM.isAwaitingBluetoothPermission ? "Waiting for Bluetooth permission…" : "Disconnected")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if deviceVM.connectionState == .connecting {
                        ProgressView().controlSize(.small)
                    } else if !deviceVM.isBluetoothPermissionDenied {
                        Button("Connect") { Task { await deviceVM.connect() } }
                            .buttonStyle(.borderedProminent).controlSize(.small)
                    }

                    if let error = deviceVM.connectionError, !deviceVM.isBluetoothPermissionDenied {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    // Battery
                    QuickBatteryView()

                    // ANC
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Noise Control").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Picker("ANC", selection: Binding(
                            get: { nc.ancMode },
                            set: { nc.selectANCMode($0) }
                        )) {
                            Image(systemName: "ear").tag(ANCMode.transparency)
                            Image(systemName: "ear.trianglebadge.exclamationmark").tag(ANCMode.noiseCancellation)
                            Image(systemName: "ear.badge.waveform").tag(ANCMode.off)
                        }
                        .pickerStyle(.segmented)
                        .help("Transparency / Noise Cancellation / Off")

                        if nc.ancMode == .noiseCancellation {
                            HStack(spacing: 4) {
                                Text("Light").font(.caption2).foregroundStyle(.tertiary)
                                Slider(value: $nc.ancDepth, in: 0...1, onEditingChanged: { if !$0 { nc.commitDepth() } })
                                    .controlSize(.small)
                                Text("Deep").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(8)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))

                    // Sound + Codec
                    VStack(spacing: 6) {
                        HStack {
                            Text("Sound Mode").font(.caption)
                            Spacer(minLength: 4)
                            Picker("", selection: Binding(
                                get: { audioVM.soundMode },
                                set: { audioVM.selectSoundMode($0) }
                            )) {
                                ForEach(SoundMode.allCases) { Text($0.displayName).tag($0) }
                            }
                            .labelsHidden().pickerStyle(.menu).controlSize(.small)
                        }
                        HStack {
                            Text("Codec").font(.caption)
                            Spacer(minLength: 4)
                            Text(audioVM.codec.displayName).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(10)
            }
        }
        .frame(width: 260)
    }
}
