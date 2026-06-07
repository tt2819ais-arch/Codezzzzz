import Foundation

struct NetworkReport: Codable, Equatable {
    let ip: String
    let city: String
    let country: String
    let asn: String
    let ping: Double
    let downloadSpeed: Double
    let uploadSpeed: Double
    let packetLoss: Double
    let dnsTimeouts: Int
    let latencyJitter: Double
    let networkType: String
    let localTime: String

    /// Two or more red flags → we treat the connection as likely throttled/jammed.
    var isJammed: Bool {
        var flags = 0
        if ping > 300 { flags += 1 }
        if packetLoss > 30 { flags += 1 }
        if downloadSpeed < 0.5 { flags += 1 }
        if dnsTimeouts > 0 { flags += 1 }
        if latencyJitter > 120 { flags += 1 }
        return flags >= 2
    }

    /// Overall quality 0...1, used to drive the gauge ring + status copy.
    var qualityScore: Double {
        var score = 1.0
        if ping > 60 { score -= min(0.35, (ping - 60) / 600) }
        if packetLoss > 0 { score -= min(0.30, packetLoss / 100) }
        if downloadSpeed < 20 { score -= min(0.25, (20 - max(downloadSpeed, 0)) / 80) }
        if latencyJitter > 30 { score -= min(0.20, (latencyJitter - 30) / 300) }
        if dnsTimeouts > 0 { score -= 0.10 }
        return max(0.05, min(1.0, score))
    }

    var statusTitle: String {
        if isJammed { return "Соединение ограничено" }
        switch qualityScore {
        case 0.78...: return "Отличное соединение"
        case 0.55..<0.78: return "Хорошее соединение"
        case 0.32..<0.55: return "Нестабильно"
        default: return "Слабое соединение"
        }
    }
}
