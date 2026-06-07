import SwiftUI

/// A standard rounded card backed by a system material.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

/// A small section heading used above grouped content.
struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
            }
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
        }
    }
}

/// A labelled key/value row, optionally tappable to reveal an explanation.
struct InfoRow: View {
    let key: String
    let value: String
    var valueColor: Color = .primary
    var monospaced: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .modifier(MonospacedIf(enabled: monospaced))
        }
        .font(.subheadline)
    }
}

private struct MonospacedIf: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content.monospacedDigit()
        } else {
            content
        }
    }
}
