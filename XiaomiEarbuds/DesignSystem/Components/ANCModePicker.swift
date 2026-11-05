import SwiftUI

// MARK: - ANC Mode Picker

struct ANCModePicker: View {
    @Binding var selectedMode: ANCMode

    var body: some View {
        Picker("Noise Control", selection: $selectedMode) {
            ForEach(ANCMode.allCases) { mode in
                Label(mode.displayName, systemImage: mode.sfSymbol)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Noise control mode")
        .accessibilityValue(selectedMode.displayName)
    }
}
