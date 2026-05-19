import Foundation

@MainActor
final class HealthViewModel: ObservableObject {
    @Published var selectedRange: HealthRange = .week
    @Published var points: [StepPoint] = []
    @Published var isLoading = false

    private let service = HealthKitService()

    func load() {
        Task {
            isLoading = true
            defer { isLoading = false }
            try? await service.requestAccess()
            points = await service.fetchSteps(range: selectedRange)
        }
    }

    var total: Double { points.map(\.steps).reduce(0, +) }
    var max: Double { points.map(\.steps).max() ?? 0 }
    var avg: Double { points.isEmpty ? 0 : total / Double(points.count) }
}
