import SwiftUI

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
        .navigationTitle(deviceVM.device.name)
        .frame(minWidth: 680, idealWidth: 780, minHeight: 500, idealHeight: 600)
    }

    private var disconnectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "headphones")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Earbuds Disconnected")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(deviceVM.connectionError ?? "Connect your REDMI Buds 8 Pro to get started.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            if deviceVM.connectionState == .connecting {
                ProgressView("Connecting…")
                    .controlSize(.small)
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
