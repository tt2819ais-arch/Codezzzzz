import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            InternetDiagnosticsView()
                .tabItem { Label("Internet", systemImage: "network") }
            HealthStatsView()
                .tabItem { Label("Health", systemImage: "heart.text.square") }
        }
    }
}
