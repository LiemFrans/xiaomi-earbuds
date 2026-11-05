import SwiftUI

// MARK: - Codec Radio Group

struct CodecRadioGroup: View {
    @Binding var selectedCodec: AudioCodec

    var body: some View {
        Picker("Audio Codec", selection: $selectedCodec) {
            ForEach(AudioCodec.allCases) { codec in
                VStack(alignment: .leading, spacing: 2) {
                    Text(codec.displayName)
                    Text(codec.description)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.labelSecondary)
                }
                .tag(codec)
                .accessibilityLabel("\(codec.displayName), \(codec.description)")
            }
        }
        .pickerStyle(.radioGroup)
        .accessibilityLabel("Audio codec selection")
    }
}
