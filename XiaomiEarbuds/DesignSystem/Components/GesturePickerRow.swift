import SwiftUI

// MARK: - Gesture Picker Row

struct GesturePickerRow: View {
    let gestureName: String
    @Binding var selectedAction: GestureAction

    var body: some View {
        LabeledContent(gestureName) {
            Picker(gestureName, selection: $selectedAction) {
                ForEach(GestureAction.allCases) { action in
                    Text(action.displayName).tag(action)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 160)
        }
        .accessibilityLabel(gestureName)
        .accessibilityValue(selectedAction.displayName)
    }
}
