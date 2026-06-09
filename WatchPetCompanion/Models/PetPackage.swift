import Foundation

struct PetPackage: Identifiable, Equatable {
    let id: String
    let name: String
    let species: String
    let style: String
    let author: String?
    let canvas: PetCanvas
    let animations: [PetAction: PetAnimation]
    let rootURL: URL

    var sortedActions: [PetAction] {
        PetAction.allCases.filter { animations[$0] != nil }
    }
}

struct PetCanvas: Codable, Equatable {
    let width: Int
    let height: Int
    let scale: Int?
}

struct PetAnimation: Equatable {
    let action: PetAction
    let relativePath: String
    let fps: Int
    let loop: Bool
    let frameURLs: [URL]
}

enum PetAction: String, Codable, CaseIterable, Identifiable {
    case idle
    case happy
    case hungry
    case eat
    case sleep
    case pet
    case sad
    case levelUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .idle: return "??"
        case .happy: return "??"
        case .hungry: return "??"
        case .eat: return "???"
        case .sleep: return "??"
        case .pet: return "??"
        case .sad: return "??"
        case .levelUp: return "??"
        }
    }
}

struct PetPackageManifest: Codable {
    let format: String
    let formatVersion: String
    let id: String
    let name: String
    let species: String
    let style: String
    let author: String?
    let preview: String?
    let icon: String?
    let canvas: PetCanvas
    let animations: [String: PetAnimationManifest]
}

struct PetAnimationManifest: Codable {
    let path: String
    let fps: Int
    let loop: Bool
}
