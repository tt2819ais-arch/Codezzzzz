import SwiftUI

/// Central design tokens for NetPulse.
///
/// The palette is deliberately restrained: a single muted teal accent on top of
/// system materials and adaptive grays. No neon, no gradients fighting for
/// attention — the data is the hero.
enum Theme {
    /// Primary accent. A calm, slightly desaturated teal that reads well in
    /// both light and dark mode.
    static let accent = Color(red: 0.10, green: 0.52, blue: 0.52)

    /// Secondary accent for positive / healthy states.
    static let good = Color(red: 0.18, green: 0.55, blue: 0.34)

    /// Warning state — a warm amber, not a harsh yellow.
    static let warn = Color(red: 0.80, green: 0.55, blue: 0.16)

    /// Problem state — a muted brick red.
    static let bad = Color(red: 0.72, green: 0.26, blue: 0.22)

    static let cardCornerRadius: CGFloat = 18
    static let cardPadding: CGFloat = 16
    static let stackSpacing: CGFloat = 16
}

extension Color {
    /// Maps a qualitative rating to a palette color.
    static func rating(_ rating: Rating) -> Color {
        switch rating {
        case .good: return Theme.good
        case .fair: return Theme.warn
        case .poor: return Theme.bad
        case .unknown: return .secondary
        }
    }
}

/// A qualitative grade applied to an individual metric.
enum Rating {
    case good, fair, poor, unknown
}
