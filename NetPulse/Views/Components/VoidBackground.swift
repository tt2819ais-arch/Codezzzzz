import SwiftUI

/// Pure-black "Void" backdrop with slowly drifting aurora orbs and a vignette.
/// Cheap to render: a handful of blurred radial gradients animated with a single
/// repeating spring, so it stays smooth even on older devices.
struct VoidBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black

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
