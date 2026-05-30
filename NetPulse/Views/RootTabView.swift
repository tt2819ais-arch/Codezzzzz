import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        TabView {
            InternetDiagnosticsView()
                .tabItem { Label("Сеть", systemImage: "wifi") }

            HealthStatsView()
                .tabItem { Label("Шаги", systemImage: "figure.walk") }

            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape") }
        }
    }
}
