import SwiftUI

// MARK: - Rename Sheet

/// Sheet for renaming the connected device.
/// Validates: non-empty, max 30 characters.
struct RenameSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var newName: String = "REDMI Buds 8 Pro"
    @FocusState private var isTextFieldFocused: Bool

    private let maxCharacters = 30

    private var isValid: Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxCharacters
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Rename Device")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                TextField("Device name", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .onChange(of: newName) { _, newValue in
                        if newValue.count > maxCharacters {
                            newName = String(newValue.prefix(maxCharacters))
                        }
                    }
                    .accessibilityLabel("Device name")

                HStack {
                    if !isValid && !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                        Text("Name cannot be empty.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Text("\(newName.count)/\(maxCharacters)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    // Will send rename command to device
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 320)
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

// MARK: - Preview
