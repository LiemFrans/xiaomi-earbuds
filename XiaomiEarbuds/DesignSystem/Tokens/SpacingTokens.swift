import SwiftUI

enum Spacing {

    // MARK: - Base Scale

    /// 4pt — Extra small spacing
    static let xs: CGFloat = 4

    /// 8pt — Small spacing
    static let sm: CGFloat = 8

    /// 12pt — Medium spacing
    static let md: CGFloat = 12

    /// 16pt — Large spacing
    static let lg: CGFloat = 16

    /// 20pt — Extra large spacing
    static let xl: CGFloat = 20

    // MARK: - Layout Dimensions

    static let sidebarWidth: CGFloat = 200
    static let popoverWidth: CGFloat = 320
    static let popoverMaxHeight: CGFloat = 480

    // MARK: - Window Sizes

    enum Window {
        static let minWidth: CGFloat = 440
        static let minHeight: CGFloat = 520

        static let defaultWidth: CGFloat = 480
        static let defaultHeight: CGFloat = 640

        static let maxWidth: CGFloat = 600
        static let maxHeight: CGFloat = 800
    }

    // MARK: - Component Sizes

    enum Component {
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 40
        static let statusDotSize: CGFloat = 8
        static let batteryGaugeHeight: CGFloat = 8
        static let deviceImageSize: CGFloat = 80
    }

    // MARK: - Corner Radii

    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
    }
}

// MARK: - Padding Helpers

extension View {
    func paddingCard() -> some View {
        self.padding(Spacing.md)
    }

    func paddingSection() -> some View {
        self.padding(.vertical, Spacing.sm)
    }
}
