import SwiftUI

enum TypographyTokens {

    // MARK: - Font Styles

    /// 17pt — Used for section titles and device name
    static let title2: Font = .title2

    /// 13pt bold — Used for section headers and emphasis
    static let headline: Font = .headline

    /// 13pt — Primary reading font
    static let body: Font = .body

    /// 12pt — Secondary descriptions
    static let callout: Font = .callout

    /// 10pt — Tertiary labels, timestamps
    static let caption: Font = .caption

    // MARK: - Weighted Variants

    static let headlineBold: Font = .headline.bold()
    static let bodyMedium: Font = .body.weight(.medium)
    static let captionMedium: Font = .caption.weight(.medium)

    // MARK: - Monospaced (firmware versions, hex values)

    static let monoBody: Font = .body.monospaced()
    static let monoCaption: Font = .caption.monospaced()
}

// MARK: - View Modifier Helpers

extension View {
    func typographyTitle2() -> some View {
        self.font(TypographyTokens.title2)
    }

    func typographyHeadline() -> some View {
        self.font(TypographyTokens.headline)
    }

    func typographyBody() -> some View {
        self.font(TypographyTokens.body)
    }

    func typographyCallout() -> some View {
        self.font(TypographyTokens.callout)
    }

    func typographyCaption() -> some View {
        self.font(TypographyTokens.caption)
    }
}

// MARK: - Text Convenience

extension Text {
    func secondaryLabel() -> Text {
        self
            .font(TypographyTokens.callout)
            .foregroundColor(ColorTokens.labelSecondary)
    }

    func tertiaryLabel() -> Text {
        self
            .font(TypographyTokens.caption)
            .foregroundColor(ColorTokens.labelTertiary)
    }
}
