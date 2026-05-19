import Foundation
import HealthKit

struct StepPoint: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Double
}

enum HealthRange: String, CaseIterable { case day, week, month, all }

final class HealthKitService {
    private let store = HKHealthStore()

    func requestAccess() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let steps = HKObjectType.quantityType(forIdentifier: .stepCount)!
        try await store.requestAuthorization(toShare: [], read: [steps])
    }

    func fetchSteps(range: HealthRange) async -> [StepPoint] {
        let count = range == .day ? 24 : (range == .week ? 7 : (range == .month ? 30 : 120))
        return (0..<count).map { i in
            StepPoint(date: Calendar.current.date(byAdding: .day, value: -i, to: .now) ?? .now,
                      steps: Double.random(in: 200...14000))
        }.reversed()
    }
}
