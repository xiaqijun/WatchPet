import Foundation

struct ImportedPetPackage: Equatable {
    let id: String
    let name: String
    let species: String
    let style: String
    let rootURL: URL
    let animations: [PetAction: ImportedPetAnimation]

    func frameURLs(for action: PetAction) -> [URL] {
        animations[action]?.frameURLs ?? []
    }
}

struct ImportedPetAnimation: Equatable {
    let action: PetAction
    let fps: Int
    let loop: Bool
    let frameURLs: [URL]
}

struct ImportedPetManifest: Codable {
    let format: String
    let formatVersion: String
    let id: String
    let name: String
    let species: String
    let style: String
    let animations: [String: ImportedPetAnimationManifest]
}

struct ImportedPetAnimationManifest: Codable {
    let path: String
    let fps: Int
    let loop: Bool
}
