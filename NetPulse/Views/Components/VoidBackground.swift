import SwiftUI

/// Pure-black "Void" backdrop: a deep starfield, slowly drifting aurora orbs and
/// a vignette that focuses the eye on the content. Everything is GPU-cheap — a
/// handful of blurred radial gradients plus a static, lightly twinkling star
/// layer — so it stays buttery smooth even on older devices.
struct VoidBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Base: a subtle vertical lift from pure black to a faint indigo so the
            // void reads as "deep space" rather than a flat black rectangle.
            LinearGradient(
                colors: [Color.black, Color(red: 0.02, green: 0.02, blue: 0.06)],
                startPoint: .top,
                endPoint: .bottom
            )

            Starfield()
                .opacity(0.9)

            orb(Color(red: 0.42, green: 0.18, blue: 0.95), size: 420)
                .offset(x: animate ? -130 : -70, y: animate ? -300 : -230)

            orb(Color(red: 0.06, green: 0.55, blue: 0.98), size: 460)
                .offset(x: animate ? 150 : 90, y: animate ? -80 : -150)

            orb(Color(red: 0.0, green: 0.82, blue: 0.70), size: 380)
                .offset(x: animate ? -120 : -180, y: animate ? 320 : 380)

            orb(Color(red: 0.92, green: 0.16, blue: 0.58), size: 340)
                .offset(x: animate ? 160 : 110, y: animate ? 340 : 270)

            RadialGradient(
                colors: [.clear, .black.opacity(0.72)],
                center: .center,
                startRadius: 180,
                endRadius: 640
            )
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private func orb(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.55), color.opacity(0.0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 70)
    }
}

/// A deterministic field of tiny stars that breathe in and out. Positions and
/// sizes are seeded so the layout is stable across redraws; a single shared
/// animation drives a gentle, offset twinkle.
private struct Starfield: View {
    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let baseOpacity: Double
        let phase: Double
    }

    @State private var twinkle = false

    private let stars: [Star] = {
        var generator = SeededGenerator(seed: 20_260_608)
        return (0..<90).map { index in
            Star(
                id: index,
                x: CGFloat.random(in: 0...1, using: &generator),
                y: CGFloat.random(in: 0...1, using: &generator),
                size: CGFloat.random(in: 0.8...2.6, using: &generator),
                baseOpacity: Double.random(in: 0.18...0.85, using: &generator),
                phase: Double.random(in: 0...1, using: &generator)
            )
        }
    }()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x * proxy.size.width,
                                  y: star.y * proxy.size.height)
                        .opacity(opacity(for: star))
                        .blur(radius: star.size > 2 ? 0.4 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                twinkle = true
            }
        }
    }

    private func opacity(for star: Star) -> Double {
        // Offset each star's twinkle by its phase so they don't pulse in unison.
        let lift = twinkle ? 0.0 : (0.35 * (1 - star.phase) + 0.05)
        return min(1.0, max(0.05, star.baseOpacity - lift))
    }
}

/// Tiny linear-congruential generator so star positions are reproducible
/// (no Foundation seeding dance, fully deterministic across launches).
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed != 0 ? seed : 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
