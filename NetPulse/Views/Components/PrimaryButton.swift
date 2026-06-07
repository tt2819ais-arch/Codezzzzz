import SwiftUI

/// Press-reactive button style: springy scale + brightness dip while held.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Filled gradient call-to-action with built-in haptic + loading state.
struct PrimaryButton: View {
    var title: String
    var systemImage: String
    var isLoading: Bool = false
    var colors: [Color] = [Color(red: 0.45, green: 0.32, blue: 1.0),
                           Color(red: 0.13, green: 0.6, blue: 1.0)]
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.impact(.medium)
            action()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: colors.first?.opacity(0.5) ?? .clear, radius: 16, y: 8)
        }
        .buttonStyle(PressableStyle())
        .disabled(isLoading)
    }
}

/// Secondary glass button.
struct SecondaryButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.soft()
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
    }
}
