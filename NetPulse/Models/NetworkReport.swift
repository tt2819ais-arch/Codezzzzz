import Foundation

struct NetworkReport: Codable {
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

    var isJammed: Bool {
        var flags = 0
        if ping > 300 { flags += 1 }
        if packetLoss > 30 { flags += 1 }
        if downloadSpeed < 0.5 { flags += 1 }
        if dnsTimeouts > 0 { flags += 1 }
        if latencyJitter > 120 { flags += 1 }
        return flags >= 2
    }
}
