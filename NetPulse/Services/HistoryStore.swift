import Foundation

/// Persists completed diagnostics runs to disk as JSON so the user can see
/// trends over time. Capped to a reasonable number of entries.
final class HistoryStore {
    static let shared = HistoryStore()

    private let maxEntries = 100
    private let fileURL: URL

    init(filename: String = "history.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent(filename)
    }

    func load() -> [NetworkReport] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoded = (try? JSONDecoder().decode([NetworkReport].self, from: data)) ?? []
        return decoded.sorted { $0.timestamp > $1.timestamp }
    }

    @discardableResult
    func append(_ report: NetworkReport) -> [NetworkReport] {
        var all = load()
        all.insert(report, at: 0)
        if all.count > maxEntries {
            all = Array(all.prefix(maxEntries))
        }
        persist(all)
        return all
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func persist(_ reports: [NetworkReport]) {
        guard let data = try? JSONEncoder().encode(reports) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
