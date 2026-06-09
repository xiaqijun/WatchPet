import Foundation
import HealthKit

final class HealthStepProvider {
    private let healthStore = HKHealthStore()

    func requestAuthorizationIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: [stepType])
        } catch {
            // MVP：授权失败时静默降级，不影响养宠物主流程。
            print("HealthKit authorization failed: \(error)")
        }
    }

    func todayStepCount() async -> Int {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let count = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(count))
            }
            healthStore.execute(query)
        }
    }
}
