import SwiftUI

@main
struct NetPulseApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settings)
                .tint(Theme.accent)
                .preferredColorScheme(settings.appearance.colorScheme)
        }
    }
}
