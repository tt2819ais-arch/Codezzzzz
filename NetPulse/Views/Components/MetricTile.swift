import SwiftUI

/// A compact tile that headlines a single measurement: big value, unit, label,
/// and a colored rating dot. Used in the diagnostics summary grid.
struct MetricTile: View {
    let title: String
    let value: String
    let unit: String
    var systemImage: String
    var rating: Rating = .unknown

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.footnote)
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Circle()
                    .fill(Color.rating(rating))
                    .frame(width: 8, height: 8)
                    .opacity(rating == .unknown ? 0 : 1)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
