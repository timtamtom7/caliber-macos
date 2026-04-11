import SwiftUI
import AppKit

enum Theme {

    // MARK: - Colors

    enum Colors {
        static let accent = NSColor(calibratedRed: 0.0, green: 0.478, blue: 1.0, alpha: 1.0) // #007AFF
        static let selectionFill = NSColor(calibratedRed: 0.0, green: 0.478, blue: 1.0, alpha: 0.2) // #007AFF 20%
        static let selectionStroke = NSColor.white
        static let labelBackground = NSColor(calibratedWhite: 0.1, alpha: 0.85)
        static let cornerHandle = NSColor.white
        static let cornerHandleBorder = NSColor.darkGray
        static let overlayDim = NSColor.black.withAlphaComponent(0.15)
    }

    // MARK: - Dimensions

    enum Dimensions {
        static let cornerHandleSize: CGFloat = 8
        static let strokeWidth: CGFloat = 1.0
        static let dashPattern: [CGFloat] = [4, 4]
        static let labelPadding: CGFloat = 8
        static let labelCornerRadius: CGFloat = 6
        static let labelFontSize: CGFloat = 12
    }

    // MARK: - Animation

    enum Animation {
        static let flashDuration: TimeInterval = 0.8
    }

    // MARK: - Cursor

    enum Cursor {
        static let crosshair = NSCursor.crosshair
        static let arrow = NSCursor.arrow
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 6
        static let large: CGFloat = 8
        static let extraLarge: CGFloat = 12
    }

    // MARK: - Typography

    enum Typography {
        static let captionFontSize: CGFloat = 11
        static let bodyFontSize: CGFloat = 13
        static let headlineFontSize: CGFloat = 16
        static let titleFontSize: CGFloat = 20
    }
}
