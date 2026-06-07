import Foundation

@MainActor
final class InternetDiagnosticsViewModel: ObservableObject {
    @Published private(set) var report: NetworkReport?
    @Published private(set) var history: [NetworkReport] = []
    @Published private(set) var isRunning = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var phaseText: String = ""

    private let engine = NetworkDiagnosticsEngine()
    private let store = HistoryStore.shared

    init() {
        history = store.load()
        report = history.first
    }

    func run(settings: AppSettings) {
        guard !isRunning else { return }
        let options = NetworkDiagnosticsEngine.Options(
            pingCount: max(3, settings.pingCount),
            runThroughput: settings.runThroughput
        )
        let haptics = settings.hapticsEnabled

        Task {
            isRunning = true
            progress = 0.02
            phaseText = NetworkDiagnosticsEngine.Phase.identity.rawValue

            let result = await engine.run(options: options) { [weak self] phase in
                Task { @MainActor in
                    guard let self else { return }
                    self.progress = phase.fraction
                    self.phaseText = phase.rawValue
                }
            }

            report = result
            history = store.append(result)
            isRunning = false
            progress = 1

            if haptics {
                result.isLikelyRestricted ? Haptics.warning() : Haptics.success()
            }
        }
    }

    func clearHistory() {
        store.clear()
        history = []
    }

    /// Plain-text snapshot for sharing.
    func shareText() -> String {
        guard let r = report else { return "NetPulse — нет данных" }
        let f = NetReportFormat.self
        return """
        NetPulse — отчёт о сети
        \(r.timestamp.formatted(date: .abbreviated, time: .shortened))

        Оценка: \(r.qualityScore)/100 (\(r.qualityLabel))
        Провайдер: \(r.isp)
        Город: \(r.city)\(r.country.isEmpty ? "" : ", \(r.country)")
        IP: \(r.ip)
        Тип сети: \(r.connectionType.rawValue)

        Задержка: \(f.ms(r.latencyMs))
        Джиттер: \(f.ms(r.jitterMs))
        Потери: \(f.percent(r.packetLoss))
        Загрузка: \(f.mbps(r.downloadMbps))
        Отдача: \(f.mbps(r.uploadMbps))
        """
    }
}

/// Shared formatting helpers so values render identically everywhere.
enum NetReportFormat {
    static func ms(_ v: Double) -> String { "\(Int(v.rounded())) мс" }
    static func mbps(_ v: Double) -> String { v <= 0 ? "—" : String(format: "%.1f Mbps", v) }
    static func percent(_ v: Double) -> String { String(format: "%.1f%%", v) }
}
