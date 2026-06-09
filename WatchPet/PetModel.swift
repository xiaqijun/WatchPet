import Foundation

enum PetAction: String, Codable, CaseIterable {
    case idle
    case happy
    case hungry
    case eat
    case sleep
    case pet
    case sad
    case levelUp
}

struct PetModel: Codable, Equatable {
    var id: UUID = UUID()
    var name: String = "Mochi"

    /// 0...100；越高越饱
    var hunger: Int = 80

    /// 0...100；越高越开心
    var mood: Int = 80

    /// 0...100；越高越有精神
    var energy: Int = 80

    var exp: Int = 0
    var level: Int = 1

    var lastUpdatedAt: Date = Date()
    var lastCareAt: Date = Date()

    var expToNextLevel: Int {
        100 + (level - 1) * 40
    }
}
