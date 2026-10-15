
import SwiftUI

enum WalletThemePreset {
    case minimalCalm
    case premiumFinance
    case modernPlayful
    case softModern
}

enum WalletTheme {
    // Change this value to preview different themes
    static let current: WalletThemePreset = .softModern

    static let cornerRadius: CGFloat = 20
    static let horizontalPadding: CGFloat = 22

    // MARK: - Primary Colors

    static var navy: Color {
        switch current {
        case .minimalCalm:
            return Color(red: 0.28, green: 0.42, blue: 0.38)
        case .premiumFinance:
            return Color(red: 0.07, green: 0.12, blue: 0.21)
        case .modernPlayful:
            return Color(red: 0.43, green: 0.33, blue: 0.73)
        case .softModern:
            return Color(red: 0.20, green: 0.23, blue: 0.34)
        }
    }

    static var gold: Color {
        switch current {
        case .minimalCalm:
            return Color(red: 0.61, green: 0.73, blue: 0.67)
        case .premiumFinance:
            return Color(red: 0.83, green: 0.68, blue: 0.42)
        case .modernPlayful:
            return Color(red: 0.98, green: 0.55, blue: 0.73)
        case .softModern:
            return Color(red: 0.72, green: 0.66, blue: 0.85)
        }
    }

    static var cream: Color {
        switch current {
        case .minimalCalm:
            return Color(red: 0.95, green: 0.97, blue: 0.94)
        case .premiumFinance:
            return Color(red: 0.98, green: 0.97, blue: 0.95)
        case .modernPlayful:
            return Color(red: 0.98, green: 0.96, blue: 0.99)
        case .softModern:
            return Color(red: 0.97, green: 0.965, blue: 0.95)
        }
    }

    static var green: Color {
        switch current {
        case .minimalCalm:
            return Color(red: 0.32, green: 0.56, blue: 0.46)
        case .premiumFinance:
            return Color(red: 0.23, green: 0.54, blue: 0.40)
        case .modernPlayful:
            return Color(red: 0.34, green: 0.63, blue: 0.80)
        case .softModern:
            return Color(red: 0.35, green: 0.59, blue: 0.51)
        }
    }

    // MARK: - Semantic Colors

    static func background(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            switch current {
            case .minimalCalm:
                return Color(red: 0.09, green: 0.12, blue: 0.11)
            case .premiumFinance:
                return Color(red: 0.045, green: 0.065, blue: 0.10)
            case .modernPlayful:
                return Color(red: 0.10, green: 0.08, blue: 0.16)
            case .softModern:
                return Color(red: 0.09, green: 0.09, blue: 0.14)
            }
        }

        return cream
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            switch current {
            case .minimalCalm:
                return Color(red: 0.13, green: 0.16, blue: 0.15)
            case .premiumFinance:
                return Color(red: 0.10, green: 0.14, blue: 0.20)
            case .modernPlayful:
                return Color(red: 0.16, green: 0.12, blue: 0.23)
            case .softModern:
                return Color(red: 0.16, green: 0.15, blue: 0.22)
            }
        }

        return .white
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        if scheme == .dark {
            return .white
        }

        switch current {
        case .minimalCalm:
            return Color(red: 0.20, green: 0.29, blue: 0.26)
        case .premiumFinance:
            return navy
        case .modernPlayful:
            return Color(red: 0.29, green: 0.20, blue: 0.47)
        case .softModern:
            return Color(red: 0.20, green: 0.23, blue: 0.34)
        }
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        switch current {
        case .minimalCalm:
            return scheme == .dark
                ? Color(red: 0.70, green: 0.76, blue: 0.73)
                : Color(red: 0.45, green: 0.52, blue: 0.49)

        case .premiumFinance:
            return scheme == .dark
                ? Color(red: 0.69, green: 0.73, blue: 0.79)
                : Color(red: 0.43, green: 0.46, blue: 0.51)

        case .modernPlayful:
            return scheme == .dark
                ? Color(red: 0.79, green: 0.75, blue: 0.88)
                : Color(red: 0.52, green: 0.46, blue: 0.62)

        case .softModern:
            return scheme == .dark
                ? Color(red: 0.77, green: 0.75, blue: 0.84)
                : Color(red: 0.49, green: 0.47, blue: 0.56)
        }
    }
}
