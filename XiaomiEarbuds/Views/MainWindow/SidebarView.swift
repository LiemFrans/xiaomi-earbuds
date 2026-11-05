import SwiftUI

// MARK: - Sidebar View

/// Navigation sidebar listing all pages, with device status at the bottom.
struct SidebarView: View {
    @Binding var selection: SidebarItem
    var isConnected: Bool = true
    var firmwareVersion: String = "3.2.2.6"

    var body: some View {
        List(selection: $selection) {
            ForEach(SidebarItem.allCases) { item in
                NavigationLink(value: item) {
                    Label(item.label, systemImage: item.icon)
                }
                .accessibilityLabel(item.label)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            deviceStatusFooter
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Device Status Footer

    private var deviceStatusFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .padding(.bottom, 4)

            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
                Text(isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Firmware \(firmwareVersion)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Device \(isConnected ? "connected" : "disconnected"), firmware version \(firmwareVersion)")
    }
}

// MARK: - Preview
