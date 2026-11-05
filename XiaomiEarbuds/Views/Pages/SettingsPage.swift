import SwiftUI

struct SettingsPage: View {
    @Environment(SettingsViewModel.self) private var vm
    @Environment(DeviceViewModel.self) private var deviceVM

    @State private var showRenameSheet = false
    @State private var showFindDeviceSheet = false
    @State private var showUnpairConfirmation = false

    var body: some View {
        Form {
            Section("Device Features") {
                Toggle("Dual Connection", isOn: Binding(
                    get: { vm.dualConnection },
                    set: { _ in vm.toggleDualConnection() }
                ))
                Toggle("Answer Calls Automatically", isOn: Binding(
                    get: { vm.autoAnswer },
                    set: { _ in vm.toggleAutoAnswer() }
                ))
            }

            Section("Actions") {
                Button("Rename Device…") { showRenameSheet = true }
                Button("Find Device…") { showFindDeviceSheet = true }
            }

            Section("Device Info") {
                LabeledContent("Firmware", value: vm.firmwareVersion)
                LabeledContent("Name", value: vm.deviceName)
            }

            Section {
                Button("Disconnect") { Task { await deviceVM.disconnect() } }
                    .foregroundStyle(.blue)
                Button("Unpair Device") { showUnpairConfirmation = true }
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .sheet(isPresented: $showRenameSheet) { RenameSheet() }
        .sheet(isPresented: $showFindDeviceSheet) { FindDeviceSheet() }
        .confirmationDialog("Unpair Device", isPresented: $showUnpairConfirmation, titleVisibility: .visible) {
            Button("Unpair", role: .destructive) { Task { await deviceVM.disconnect() } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure?") }
    }
}
