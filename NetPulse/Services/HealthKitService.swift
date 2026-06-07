import Foundation
import HealthKit

struct StepPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let steps: Double
}

enum HealthRange: String, CaseIterable, Identifiable {
    case day, week, month, all
    var id: String { rawValue }
    var label: String {
        switch self {
        case .day: return "День"
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .all: return "Всё"
        }
    }
}

/// Reads step counts from HealthKit, bucketed by the selected range.
final class HealthKitService {
    enum AccessState: Equatable {
        case unavailable      // device has no HealthKit
        case authorized
        case denied
    }

    private let store = HKHealthStore()

    private var stepType: HKQuantityType? {
        HKObjectType.quantityType(forIdentifier: .stepCount)
    }

    /// Requests read access. Returns the resulting state so the UI can show an
    /// accurate empty/permission message instead of a blank chart.
    func requestAccess() async -> AccessState {
        guard HKHealthStore.isHealthDataAvailable(), let stepType else {
            return .unavailable
        }
        do {
            try await store.requestAuthorization(toShare: [], read: [stepType])
            return .authorized
        } catch {
            return .denied
        }
    }

    func fetchSteps(range: HealthRange) async -> [StepPoint] {
        guard HKHealthStore.isHealthDataAvailable(), let stepType else { return [] }

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
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, _ in
                var points: [StepPoint] = []
                results?.enumerateStatistics(from: anchor, to: now) { stats, _ in
                    let value = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    points.append(StepPoint(date: stats.startDate, steps: value))
                }
                continuation.resume(returning: points)
            }
            store.execute(query)
        }
    }
}
