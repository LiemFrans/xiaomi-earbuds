import SwiftUI
import AppKit

struct MainWindowView: View {
    @Environment(DeviceViewModel.self) private var deviceVM
    @State private var selectedItem: SidebarItem = .overview

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $selectedItem,
                isConnected: deviceVM.isConnected,
                firmwareVersion: deviceVM.device.firmwareVersion
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            if deviceVM.isConnected {
                ContentRouter(selection: selectedItem)
            } else {
                disconnectedView
            }
        }
        .navigationTitle("Xiaomi Earbuds")
        .frame(minWidth: 680, idealWidth: 780, minHeight: 500, idealHeight: 600)
    }

    private var disconnectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: deviceVM.isBluetoothPermissionDenied ? "hand.raised.fill" : "headphones")
                .font(.system(size: 48))
                .foregroundStyle(deviceVM.isBluetoothPermissionDenied ? AnyShapeStyle(.orange) : AnyShapeStyle(.tertiary))
            Text(deviceVM.isBluetoothPermissionDenied ? "Bluetooth Permission Needed" : "Earbuds Disconnected")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(
                deviceVM.isBluetoothPermissionDenied
                    ? "Allow Xiaomi Earbuds in System Settings → Privacy & Security → Bluetooth, then try again."
                    : (deviceVM.connectionError ?? "Connect your earbuds to get started.")
            )
            .font(.callout)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 420)

            if deviceVM.connectionState == .connecting {
                ProgressView("Connecting…")
                    .controlSize(.small)
            } else if deviceVM.isBluetoothPermissionDenied {
                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else {
                Button("Connect") {
                    Task { await deviceVM.connect() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
