import SwiftUI

@main
struct NetPulseApp: App {
    @AppStorage("manualTheme") private var manualTheme: String = "system"

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch manualTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
