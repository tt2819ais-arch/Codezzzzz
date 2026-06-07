import Foundation

/// Orchestrates a full diagnostics run and reports progress as it goes.
///
/// Phases run partly in parallel: identity/geo, latency, and connection type are
/// independent, while throughput tests run sequentially after them so they do
/// not contend with the latency probe for bandwidth (which would corrupt both).
final class NetworkDiagnosticsEngine {
    private let geo: GeoIPService
    private let latencyHost: String
    private let latencyPort: UInt16

    init(
        geo: GeoIPService = GeoIPService(),
        latencyHost: String = "1.1.1.1",
        latencyPort: UInt16 = 443
    ) {
        self.geo = geo
        self.latencyHost = latencyHost
        self.latencyPort = latencyPort
    }

    /// Progress phases, surfaced to the UI for an honest progress bar.
    enum Phase: String {
        case identity = "Определяем IP и провайдера…"
        case latency = "Измеряем задержку…"
        case download = "Тест скорости загрузки…"
        case upload = "Тест скорости отдачи…"
        case done = "Готово"

        var fraction: Double {
            switch self {
            case .identity: return 0.15
            case .latency: return 0.40
            case .download: return 0.70
            case .upload: return 0.92
            case .done: return 1.0
            }
        }
    }

    /// Settings that influence a run.
    struct Options {
        var pingCount: Int = 8
        var runThroughput: Bool = true
    }

    func run(
        options: Options = Options(),
        onProgress: @escaping (Phase) -> Void
    ) async -> NetworkReport {
        onProgress(.identity)
        async let geoInfo = geo.fetch()
        async let connType = ConnectionMonitor.currentType()

        onProgress(.latency)
        let probe = LatencyProbe(host: latencyHost, port: latencyPort)
        let latency = await probe.run(count: options.pingCount)

        var download = 0.0
        var upload = 0.0
        if options.runThroughput {
            let throughput = ThroughputProbe()
            onProgress(.download)
            download = await throughput.measureDownloadMbps()
            onProgress(.upload)
            upload = await throughput.measureUploadMbps()
        }

        let info = await geoInfo
        let connection = await connType
        onProgress(.done)

        return NetworkReport(
            timestamp: Date(),
            ip: info.ip,
            city: info.city,
            country: info.country,
            isp: info.isp,
            latencyMs: latency.averageMs,
            jitterMs: latency.jitterMs,
            packetLoss: latency.lossPercent,
            downloadMbps: download,
            uploadMbps: upload,
            connectionType: connection
        )
    }
}
