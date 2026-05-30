import SwiftUI

/// User-facing settings, persisted to `UserDefaults` and published so the UI
/// reacts to changes.
///
/// Note: `@AppStorage` is intentionally avoided here — it does not reliably
/// drive `objectWillChange` when nested inside an `ObservableObject`. Backing
/// `@Published` properties with a `didSet` that writes through to defaults is
/// the dependable pattern.
final class AppSettings: ObservableObject {
    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var label: String {
            switch self {
            case .system: return "Системная"
            case .light: return "Светлая"
            case .dark: return "Тёмная"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    @Published var appearance: Appearance { didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) } }
    @Published var pingCount: Int { didSet { defaults.set(pingCount, forKey: Keys.pingCount) } }
    @Published var runThroughput: Bool { didSet { defaults.set(runThroughput, forKey: Keys.runThroughput) } }
    @Published var autoRunOnLaunch: Bool { didSet { defaults.set(autoRunOnLaunch, forKey: Keys.autoRunOnLaunch) } }
    @Published var hapticsEnabled: Bool { didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) } }
    @Published var vpnScheme: String { didSet { defaults.set(vpnScheme, forKey: Keys.vpnScheme) } }

    private let defaults: UserDefaults

    private enum Keys {
        static let appearance = "appearance"
        static let pingCount = "pingCount"
        static let runThroughput = "runThroughput"
        static let autoRunOnLaunch = "autoRunOnLaunch"
        static let hapticsEnabled = "hapticsEnabled"
        static let vpnScheme = "vpnScheme"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.appearance: Appearance.system.rawValue,
            Keys.pingCount: 8,
            Keys.runThroughput: true,
            Keys.autoRunOnLaunch: true,
            Keys.hapticsEnabled: true,
            Keys.vpnScheme: "happplusvpn://connect",
        ])
        appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        pingCount = defaults.integer(forKey: Keys.pingCount)
        runThroughput = defaults.bool(forKey: Keys.runThroughput)
        autoRunOnLaunch = defaults.bool(forKey: Keys.autoRunOnLaunch)
        hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        vpnScheme = defaults.string(forKey: Keys.vpnScheme) ?? "happplusvpn://connect"
    }
}
