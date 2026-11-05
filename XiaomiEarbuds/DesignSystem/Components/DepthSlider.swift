import SwiftUI

struct DepthSlider: View {
    @Binding var depth: Double
    var label: String = "Depth"
    var onCommit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(TypographyTokens.headline)

            HStack {
                Text("Light")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.labelSecondary)

                Slider(value: $depth, in: 0...1, onEditingChanged: { editing in
                    if !editing { onCommit?() }
                })

                Text("Deep")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.labelSecondary)
            }
            .accessibilityLabel("\(label) level")
            .accessibilityValue("\(Int(depth * 100)) percent")
        }
    }
}
