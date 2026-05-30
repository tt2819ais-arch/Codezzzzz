import Foundation

/// Measures download and upload throughput honestly.
///
/// Two things make naive speed tests wrong:
///  1. A single small cold transfer is dominated by TCP slow-start, badly
///     understating real bandwidth.
///  2. Timing the whole request includes connection setup latency.
///
/// This probe runs a short warm-up transfer first (to open the congestion
/// window), then takes several timed samples and reports the **median** Mbps,
/// which is robust against a single anomalous sample.
///
/// Endpoints: Cloudflare's public speed-test backend, which serves/accepts an
/// arbitrary number of bytes via query/`Content-Length` and is globally fast,
/// so the client link is the bottleneck rather than the server.
struct ThroughputProbe {
    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            config.timeoutIntervalForRequest = 20
            config.allowsConstrainedNetworkAccess = true
            self.session = URLSession(configuration: config)
        }
    }

    private static let downloadBase = "https://speed.cloudflare.com/__down?bytes="
    private static let uploadURL = URL(string: "https://speed.cloudflare.com/__up")!

    // MARK: Download

    /// Returns median download throughput in Mbps, or 0 on failure.
    func measureDownloadMbps() async -> Double {
        // Warm-up (result discarded).
        _ = await downloadSampleMbps(bytes: 1_000_000)

        var samples: [Double] = []
        for bytes in [5_000_000, 10_000_000, 10_000_000] {
            if let mbps = await downloadSampleMbps(bytes: bytes) {
                samples.append(mbps)
            }
        }
        return Self.median(samples)
    }

    private func downloadSampleMbps(bytes: Int) async -> Double? {
        guard let url = URL(string: Self.downloadBase + String(bytes)) else { return nil }
        let start = Date()
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let seconds = max(Date().timeIntervalSince(start), 0.001)
            return (Double(data.count) * 8.0 / seconds) / 1_000_000
        } catch {
            return nil
        }
    }

    // MARK: Upload

    /// Returns median upload throughput in Mbps, or 0 on failure.
    func measureUploadMbps() async -> Double {
        _ = await uploadSampleMbps(bytes: 1_000_000) // warm-up

        var samples: [Double] = []
        for bytes in [3_000_000, 5_000_000, 5_000_000] {
            if let mbps = await uploadSampleMbps(bytes: bytes) {
                samples.append(mbps)
            }
        }
        return Self.median(samples)
    }

    private func uploadSampleMbps(bytes: Int) async -> Double? {
        var request = URLRequest(url: Self.uploadURL)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let payload = Data(count: bytes)
        let start = Date()
        do {
            let (_, response) = try await session.upload(for: request, from: payload)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            let seconds = max(Date().timeIntervalSince(start), 0.001)
            return (Double(bytes) * 8.0 / seconds) / 1_000_000
        } catch {
            return nil
        }
    }

    // MARK: Helpers

    private static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }
}
