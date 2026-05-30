import Foundation

@MainActor
final class HealthViewModel: ObservableObject {
    @Published var selectedRange: HealthRange = .week
    @Published private(set) var points: [StepPoint] = []
    @Published private(set) var isLoading = false
    @Published private(set) var accessState: HealthKitService.AccessState?

    private let service = HealthKitService()

    func load() {
        Task {
            isLoading = true
            defer { isLoading = false }
            if accessState == nil {
                accessState = await service.requestAccess()
            }
            guard accessState == .authorized else {
                points = []
                return
            }
            points = await service.fetchSteps(range: selectedRange)
        }
    }

    var total: Double { points.map(\.steps).reduce(0, +) }
    var peak: Double { points.map(\.steps).max() ?? 0 }
    var average: Double { points.isEmpty ? 0 : total / Double(points.count) }

    var hasData: Bool { points.contains { $0.steps > 0 } }
}
