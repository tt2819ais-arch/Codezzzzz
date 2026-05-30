import Foundation

/// Public IP, geolocation, and ISP lookup.
///
/// Uses ipinfo.io, which returns the caller's own IP plus city/country/org in a
/// single request — so no separate IP-echo call is needed. All fields are
/// optional in the response and fall back gracefully.
struct GeoIPService {
    struct Info {
        let ip: String
        let city: String
        let country: String
        let isp: String
    }

    private struct Response: Decodable {
        let ip: String?
        let city: String?
        let country: String?
        let org: String?
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch() async -> Info {
        guard let url = URL(string: "https://ipinfo.io/json") else {
            return .unknown
        }
        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 8
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .unknown
            }
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return Info(
                ip: decoded.ip ?? "—",
                city: decoded.city ?? "Неизвестно",
                country: decoded.country ?? "",
                isp: Self.cleanOrg(decoded.org) ?? "Неизвестно"
            )
        } catch {
            return .unknown
        }
    }

    /// ipinfo prefixes org with the ASN (e.g. "AS13335 Cloudflare, Inc."). Strip
    /// it for a cleaner ISP name while keeping the company.
    private static func cleanOrg(_ org: String?) -> String? {
        guard let org, !org.isEmpty else { return nil }
        if let range = org.range(of: #"^AS\d+\s+"#, options: .regularExpression) {
            return String(org[range.upperBound...])
        }
        return org
    }
}

extension GeoIPService.Info {
    static let unknown = GeoIPService.Info(ip: "—", city: "Неизвестно", country: "", isp: "Неизвестно")
}
