import Foundation
import SwiftUI

@MainActor
final class PetStore: ObservableObject {
    @Published private(set) var pet: PetModel
    @Published private(set) var currentAction: PetAction = .idle

    private let storageKey = "watchpet.pet.v1"
    private let stepProvider = HealthStepProvider()

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(PetModel.self, from: data) {
            self.pet = decoded
        } else {
            self.pet = PetModel()
        }
        applyTimeDecay()
        refreshDerivedAction()
    }

    func bootstrap() async {
        await stepProvider.requestAuthorizationIfNeeded()
        await awardStepExperience()
        save()
    }

    func feed() {
        pet.hunger = min(100, pet.hunger + 25)
        pet.mood = min(100, pet.mood + 8)
        pet.lastCareAt = Date()
        temporaryAction(.eat)
    }

    func strokePet() {
        pet.mood = min(100, pet.mood + 12)
        pet.energy = max(0, pet.energy - 2)
        pet.lastCareAt = Date()
        temporaryAction(.pet)
    }

    func sleep() {
        pet.energy = min(100, pet.energy + 30)
        pet.hunger = max(0, pet.hunger - 5)
        pet.lastCareAt = Date()
        temporaryAction(.sleep, duration: 2.5)
    }

    func addExp(_ amount: Int) {
        pet.exp += amount
        while pet.exp >= pet.expToNextLevel {
            pet.exp -= pet.expToNextLevel
            pet.level += 1
            pet.mood = min(100, pet.mood + 20)
            temporaryAction(.levelUp, duration: 2.0)
        }
        save()
    }

    func refreshDerivedAction() {
        if pet.energy < 20 {
            currentAction = .sleep
        } else if pet.hunger < 30 {
            currentAction = .hungry
        } else if pet.mood < 30 {
            currentAction = .sad
        } else if pet.mood > 85 {
            currentAction = .happy
        } else {
            currentAction = .idle
        }
    }

    private func temporaryAction(_ action: PetAction, duration: TimeInterval = 1.6) {
        currentAction = action
        save()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            refreshDerivedAction()
        }
    }

    private func applyTimeDecay() {
        let now = Date()
        let elapsedMinutes = max(0, now.timeIntervalSince(pet.lastUpdatedAt) / 60.0)

        guard elapsedMinutes >= 5 else { return }

        let hungerLoss = Int(elapsedMinutes / 30.0)       // 每 30 分钟掉 1
        let moodLoss = Int(elapsedMinutes / 45.0)         // 每 45 分钟掉 1
        let energyLoss = Int(elapsedMinutes / 60.0)       // 每 60 分钟掉 1

        pet.hunger = max(0, pet.hunger - hungerLoss)
        pet.mood = max(0, pet.mood - moodLoss)
        pet.energy = max(0, pet.energy - energyLoss)
        pet.lastUpdatedAt = now
        save()
    }

    private func awardStepExperience() async {
        let steps = await stepProvider.todayStepCount()
        let exp = min(80, steps / 250) // 每 250 步 1 exp，每天最多这一轮加 80
        if exp > 0 {
            addExp(exp)
        }
    }

    private func save() {
        pet.lastUpdatedAt = Date()
        if let data = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

extension PetStore {
    static var preview: PetStore {
        let store = PetStore()
        store.currentAction = .happy
        return store
    }
}

