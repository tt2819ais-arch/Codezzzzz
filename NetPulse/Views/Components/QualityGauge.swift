import SwiftUI

/// A radial gauge that visualizes an overall connection quality score (0–100).
/// Animated sweep, restrained styling, color driven by the rating.
struct QualityGauge: View {
    /// Score 0...100. Nil while unknown.
    let score: Int?
    let caption: String

    private var fraction: Double {
        guard let score else { return 0 }
        return min(max(Double(score) / 100.0, 0), 1)
    }

    private var color: Color {
        guard let score else { return Color.secondary.opacity(0.4) }
        switch score {
        case 80...: return Theme.good
        case 50..<80: return Theme.warn
        default: return Theme.bad
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 12)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: fraction)

            VStack(spacing: 2) {
                Text(score.map(String.init) ?? "—")
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 168, height: 168)
    }
}
