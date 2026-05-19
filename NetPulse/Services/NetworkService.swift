import Foundation

private struct IPResponse: Codable { let ip: String }

final class NetworkService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func publicIP() async throws -> String {
        let (data, response) = try await session.data(from: URL(string: "https://api.ipify.org?format=json")!)
        try Self.validate(response)
        return try JSONDecoder().decode(IPResponse.self, from: data).ip
    }

    func measureLatency(url: URL = URL(string: "https://www.google.com/generate_204")!) async -> Double {
        let start = Date()
        do {
            let (_, response) = try await session.data(from: url)
            try Self.validate(response)
            return Date().timeIntervalSince(start) * 1000
        } catch {
            return 999
        }
    }

    func estimateDownloadSpeedMbps() async -> Double {
        guard let url = URL(string: "https://speed.hetzner.de/1MB.bin") else { return 0 }
        let start = Date()
        do {
            let (data, response) = try await session.data(from: url)
            try Self.validate(response)
            let sec = max(Date().timeIntervalSince(start), 0.01)
            return (Double(data.count) * 8.0 / sec) / 1_000_000
        } catch {
            return 0
        }
    }

    func estimateUploadSpeedMbps() async -> Double {
        guard let url = URL(string: "https://httpbin.org/post") else { return 0 }
        let payload = Data(repeating: 7, count: 300_000)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = payload
        let start = Date()
        do {
            let (_, response) = try await session.data(for: request)
            try Self.validate(response)
            let sec = max(Date().timeIntervalSince(start), 0.01)
            return (Double(payload.count) * 8.0 / sec) / 1_000_000
        } catch {
            return 0
        }
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
