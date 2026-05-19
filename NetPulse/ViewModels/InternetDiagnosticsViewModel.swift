import Foundation

@MainActor
final class InternetDiagnosticsViewModel: ObservableObject {
    @Published var report: NetworkReport?
    @Published var isLoading = false
    @Published var errorText: String?
    @Published var progress: Double = 0

    private let engine = NetworkDiagnosticsEngine()

    func run() {
        Task {
            isLoading = true
            errorText = nil
            progress = 0.1
            defer { isLoading = false; progress = 1 }
            do {
                progress = 0.4
                let result = try await engine.generateReport()
                progress = 0.9
                report = result
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}
