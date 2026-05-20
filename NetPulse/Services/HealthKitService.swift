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
        guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        try await store.requestAuthorization(toShare: [], read: [steps])
    }

    func fetchSteps(range: HealthRange) async -> [StepPoint] {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return []
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        let interval: DateComponents
        let anchor: Date
        switch range {
        case .day:
            interval = DateComponents(hour: 1)
            anchor = startOfToday
        case .week:
            interval = DateComponents(day: 1)
            anchor = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        case .month:
            interval = DateComponents(day: 1)
            anchor = calendar.date(byAdding: .day, value: -29, to: startOfToday) ?? startOfToday
        case .all:
            interval = DateComponents(day: 1)
            anchor = calendar.date(byAdding: .day, value: -119, to: startOfToday) ?? startOfToday
        }

        let predicate = HKQuery.predicateForSamples(withStart: anchor, end: now, options: .strictStartDate)

        return await withCheckedContinuation { (continuation: CheckedContinuation<[StepPoint], Never>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, _ in
                var points: [StepPoint] = []
                results?.enumerateStatistics(from: anchor, to: now) { stats, _ in
                    let value = stats.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    points.append(StepPoint(date: stats.startDate, steps: value))
                }
                continuation.resume(returning: points)
            }
            store.execute(query)
        }
    }
}
