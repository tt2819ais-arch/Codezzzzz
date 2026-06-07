import Foundation

/// A single completed network diagnostics run.
///
/// All latency values are TCP round-trip times in milliseconds (measured via a
/// raw connection handshake, not an HTTP request). Throughput values are in
/// megabits per second, measured with a warm-up phase and reported as the
/// median of several samples to discount TCP slow-start.
struct NetworkReport: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let timestamp: Date

    // Identity / location
    let ip: String
    let city: String
    let country: String
    let isp: String

    // Latency (milliseconds, TCP RTT)
    let latencyMs: Double
    let jitterMs: Double
    let packetLoss: Double          // 0...100 (%)

    // Throughput (megabits per second)
    let downloadMbps: Double
    let uploadMbps: Double

    // Connection
    let connectionType: ConnectionType

    enum ConnectionType: String, Codable {
        case wifi = "Wi-Fi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case other = "Other"
        case unknown = "Unknown"

        var systemImage: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .other, .unknown: return "network"
            }
        }
    }
}

// MARK: - Derived quality assessment

extension NetworkReport {
    var latencyRating: Rating {
        switch latencyMs {
        case ..<60: return .good
        case 60..<150: return .fair
        default: return .poor
        }
    }

    var jitterRating: Rating {
        switch jitterMs {
        case ..<15: return .good
        case 15..<40: return .fair
        default: return .poor
        }
    }

    var lossRating: Rating {
        switch packetLoss {
        case ..<1: return .good
        case 1..<5: return .fair
        default: return .poor
        }
    }

    var downloadRating: Rating {
        switch downloadMbps {
        case 25...: return .good
        case 5..<25: return .fair
        default: return .poor
        }
    }

    var uploadRating: Rating {
        switch uploadMbps {
        case 10...: return .good
        case 2..<10: return .fair
        default: return .poor
        }
    }

    /// A composite 0–100 score weighted toward the factors users feel most:
    /// latency, loss, then throughput.
    var qualityScore: Int {
        func points(_ rating: Rating) -> Double {
            switch rating {
            case .good: return 1.0
            case .fair: return 0.6
            case .poor: return 0.15
            case .unknown: return 0.5
            }
        }
        let weighted =
            points(latencyRating) * 0.28 +
            points(lossRating)    * 0.24 +
            points(jitterRating)  * 0.12 +
            points(downloadRating) * 0.24 +
            points(uploadRating)  * 0.12
        return Int((weighted * 100).rounded())
    }

    var qualityLabel: String {
        switch qualityScore {
        case 80...: return "Отлично"
        case 50..<80: return "Нормально"
        default: return "Слабо"
        }
    }

    /// Heuristic flag for a throttled or restricted connection. Requires at
    /// least two independent red signals so a single blip does not trip it.
    var restrictionSignals: [String] {
        var signals: [String] = []
        if latencyMs > 250 { signals.append("Высокая задержка (\(Int(latencyMs)) мс)") }
        if packetLoss > 8 { signals.append("Потери пакетов \(String(format: "%.0f", packetLoss))%") }
        if jitterMs > 60 { signals.append("Нестабильная задержка (джиттер \(Int(jitterMs)) мс)") }
        if downloadMbps > 0 && downloadMbps < 1 { signals.append("Очень низкая скорость загрузки") }
        return signals
    }

    var isLikelyRestricted: Bool { restrictionSignals.count >= 2 }
}
