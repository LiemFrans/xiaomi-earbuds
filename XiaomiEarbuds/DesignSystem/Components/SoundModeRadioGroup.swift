import SwiftUI

// MARK: - Sound Mode Radio Group

struct SoundModeRadioGroup: View {
    @Binding var selectedMode: SoundMode

    var body: some View {
        Picker("Sound Mode", selection: $selectedMode) {
            ForEach(SoundMode.allCases) { mode in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: mode.sfSymbol)
                        .frame(width: Spacing.Component.iconSmall)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mode.displayName)
                    }
                }
                .tag(mode)
                .accessibilityLabel(mode.displayName)
            }
        }
        .pickerStyle(.radioGroup)
        .accessibilityLabel("Sound mode selection")
    }
}
