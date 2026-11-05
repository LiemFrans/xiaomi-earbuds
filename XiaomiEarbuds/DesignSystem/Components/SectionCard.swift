import SwiftUI

struct SectionCard<Content: View>: View {
    let header: String?
    @ViewBuilder let content: () -> Content

    init(header: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.header = header
        self.content = content
    }

    var body: some View {
        GroupBox {
            content()
                .padding(.top, header != nil ? Spacing.xs : 0)
        } label: {
            if let header {
                Text(header)
                    .font(TypographyTokens.headline)
                    .foregroundStyle(ColorTokens.labelPrimary)
            }
        }
    }
}
