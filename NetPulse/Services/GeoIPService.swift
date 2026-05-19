import Foundation

struct GeoInfo: Codable {
    let city: String?
    let country: String?
    let org: String?
}

final class GeoIPService {
    func geoInfo(ip: String) async throws -> GeoInfo {
        let url = URL(string: "https://ipinfo.io/\(ip)/json")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(GeoInfo.self, from: data)
    }
}
