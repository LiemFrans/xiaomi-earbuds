import SwiftUI

struct GesturesPage: View {
    @Environment(GestureViewModel.self) private var vm

    var body: some View {
        Form {
            ForEach(GestureType.allCases) { type in
                Section {
                    gestureRow(type: type, side: .left)
                    gestureRow(type: type, side: .right)
                } header: {
                    Label(type.displayName, systemImage: type.sfSymbol)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Gestures")
    }

    @ViewBuilder
    private func gestureRow(type: GestureType, side: EarbudSide) -> some View {
        let label = "\(type.displayName) \(side == .left ? "Left" : "Right")"
        let current = vm.action(for: type, side: side)

        LabeledContent(label) {
            Picker(label, selection: Binding(
                get: { current },
                set: { vm.setGesture(type: type, side: side, action: $0) }
            )) {
                ForEach(type.supportedActions, id: \.self) { action in
                    Text(action.displayName).tag(action)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 160)
        }
        .accessibilityLabel(label)
        .accessibilityValue(current.displayName)
    }
}
