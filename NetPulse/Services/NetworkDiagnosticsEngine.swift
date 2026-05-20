import Foundation
import Network

final class NetworkDiagnosticsEngine {
    private let networkService: NetworkService
    private let geoService: GeoIPService

    init(networkService: NetworkService = NetworkService(), geoService: GeoIPService = GeoIPService()) {
        self.networkService = networkService
        self.geoService = geoService
    }

    func generateReport() async throws -> NetworkReport {
        async let ip = networkService.publicIP()
        async let pingSamples = measurePingSamples()
        async let down = networkService.estimateDownloadSpeedMbps()
        async let up = networkService.estimateUploadSpeedMbps()
        async let netType = currentNetworkType()

        let ipValue = try await ip
        let geo = try await geoService.geoInfo(ip: ipValue)
        let samples = await pingSamples
        let download = await down
        let upload = await up
        let networkType = await netType

        let timeouts = samples.filter { $0 >= 999 }.count
        let successful = samples.filter { $0 < 999 }
        let avgPing = successful.isEmpty
            ? 0
            : successful.reduce(0, +) / Double(successful.count)
        let jitter = Self.jitter(successful)
        let packetLoss = samples.isEmpty
            ? 0
            : Double(timeouts) / Double(samples.count) * 100

        return NetworkReport(
            ip: ipValue,
            city: geo.city ?? "Unknown",
            country: geo.country ?? "Unknown",
            asn: geo.org ?? "N/A",
            ping: avgPing,
            downloadSpeed: download,
            uploadSpeed: upload,
            packetLoss: packetLoss,
            dnsTimeouts: timeouts,
            latencyJitter: jitter,
            networkType: networkType,
            localTime: Date.now.formatted(date: .omitted, time: .standard)
        )
    }

    private func measurePingSamples() async -> [Double] {
        var results: [Double] = []
        for _ in 0..<8 {
            results.append(await networkService.measureLatency())
        }
        return results
    }

    private static func jitter(_ samples: [Double]) -> Double {
        guard samples.count > 1 else { return 0 }
        let diffs = zip(samples.dropFirst(), samples).map { abs($0 - $1) }
        return diffs.reduce(0, +) / Double(diffs.count)
    }

    private func currentNetworkType() async -> String {
        await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "netpulse.path")
            var resumed = false
            monitor.pathUpdateHandler = { path in
                guard !resumed else { return }
                resumed = true
                let value: String
                if path.usesInterfaceType(.wifi) { value = "Wi-Fi" }
                else if path.usesInterfaceType(.cellular) { value = "Cellular" }
                else if path.usesInterfaceType(.wiredEthernet) { value = "Ethernet" }
                else { value = "Unknown" }
                monitor.cancel()
                continuation.resume(returning: value)
            }
            monitor.start(queue: queue)
        }
    }
}
