import SwiftUI

// MARK: - Find Device Sheet

/// Sheet showing an animated speaker icon while playing a sound on the earbuds.
struct FindDeviceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying: Bool = true

    var body: some View {
        VStack(spacing: 24) {
            Text("Find Device")
                .font(.headline)

            VStack(spacing: 16) {
                Image(systemName: "speaker.wave.3")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                    .symbolEffect(.variableColor.iterative, isActive: isPlaying)
                    .accessibilityHidden(true)

                Text("Playing sound on earbuds…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(height: 120)

            Button("Stop") {
                isPlaying = false
                // Will send stop sound command to device
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 280)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Find device. Playing sound on earbuds.")
    }
}

// MARK: - Preview
