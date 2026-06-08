import SwiftUI

/// Large circular gauge that visualises overall connection quality.
/// `score` is 0...1; the ring colour shifts red → amber → green and the
/// centre shows a headline value. When `isLoading` it emits a calm pulse.
struct PulseGauge: View {
    var score: Double
    var headline: String
    var caption: String
    var isLoading: Bool

    @State private var pulse = false
    @State private var rotate = false
    @State private var appeared = false

    private var tint: Color {
        switch score {
        case 0.66...: return Color(red: 0.18, green: 0.92, blue: 0.62)
        case 0.4..<0.66: return Color(red: 1.0, green: 0.76, blue: 0.24)
        default: return Color(red: 1.0, green: 0.32, blue: 0.42)
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 16)

            Circle()
                .fill(tint.opacity(0.14))
                .scaleEffect(pulse ? 1.06 : 0.78)
                .opacity(pulse ? 0.0 : 0.55)
                .blur(radius: 6)

            Circle()
                .trim(from: 0, to: isLoading ? 0.22 : max(0.001, score))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [tint.opacity(0.35), tint]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(isLoading ? (rotate ? 360 : 0) : -90))
                .shadow(color: tint.opacity(0.6), radius: 14)
                .animation(.spring(response: 1.0, dampingFraction: 0.82), value: score)

            VStack(spacing: 6) {
                Text(headline)
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: headline)
                Text(caption)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(width: 230, height: 230)
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            startAnimations()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { appeared = true }
        }
        .onChange(of: isLoading) { _ in startAnimations() }
    }

    private func startAnimations() {
        pulse = false
        withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
            pulse = true
        }
        if isLoading {
            rotate = false
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                rotate = true
            }
        }
    }
}
