import SwiftUI

struct RootTabView: View {
    @State private var selection = 0

    init() {
        // Translucent dark tab + nav bars so the Void backdrop shows through.
        let tab = UITabBarAppearance()
        tab.configureWithTransparentBackground()
        tab.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        tab.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
    }

    var body: some View {
        TabView(selection: $selection) {
            InternetDiagnosticsView()
                .tabItem { Label("Сеть", systemImage: "antenna.radiowaves.left.and.right") }
                .tag(0)
            HealthStatsView()
                .tabItem { Label("Здоровье", systemImage: "heart.fill") }
                .tag(1)
        }
        .tint(Color(red: 0.58, green: 0.5, blue: 1.0))
        .onChange(of: selection) { _ in
            // Crisp selection tick whenever the user switches tabs.
            Haptics.selection()
        }
    }
}
