import Foundation

enum WatchPetPackageError: LocalizedError {
    case missingManifest(URL)
    case unsupportedFormat(String)
    case unsupportedVersion(String)
    case missingAnimation(String)
    case missingFrames(String)

    var errorDescription: String? {
        switch self {
        case .missingManifest(let url): return "manifest.json ????\(url.path)"
        case .unsupportedFormat(let format): return "???????\(format)"
        case .unsupportedVersion(let version): return "???????\(version)"
        case .missingAnimation(let action): return "?????\(action)"
        case .missingFrames(let action): return "???? PNG ??\(action)"
        }
    }
}

final class WatchPetPackageLoader {
    static let shared = WatchPetPackageLoader()

    private let requiredActions = PetAction.allCases

    func loadBundledSample() throws -> PetPackage {
        guard let url = Bundle.main.url(forResource: "mochi", withExtension: "watchpet", subdirectory: "Resources")
            ?? Bundle.main.url(forResource: "mochi", withExtension: "watchpet") else {
            throw WatchPetPackageError.missingManifest(Bundle.main.bundleURL)
        }
        return try loadUnpackedPackage(at: url)
    }

    func loadUnpackedPackage(at rootURL: URL) throws -> PetPackage {
        let manifestURL = rootURL.appendingPathComponent("manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw WatchPetPackageError.missingManifest(manifestURL)
        }

        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(PetPackageManifest.self, from: data)

        guard manifest.format == "watchpet" else {
            throw WatchPetPackageError.unsupportedFormat(manifest.format)
        }
        guard manifest.formatVersion == "1.0.0" else {
            throw WatchPetPackageError.unsupportedVersion(manifest.formatVersion)
        }

        var animations: [PetAction: PetAnimation] = [:]
        for action in requiredActions {
            guard let spec = manifest.animations[action.rawValue] else {
                throw WatchPetPackageError.missingAnimation(action.rawValue)
            }
            let actionURL = rootURL.appendingPathComponent(spec.path)
            let frames = try frameURLs(in: actionURL)
            guard !frames.isEmpty else {
                throw WatchPetPackageError.missingFrames(action.rawValue)
            }
            animations[action] = PetAnimation(
                action: action,
                relativePath: spec.path,
                fps: spec.fps,
                loop: spec.loop,
                frameURLs: frames
            )
        }

        return PetPackage(
            id: manifest.id,
            name: manifest.name,
            species: manifest.species,
            style: manifest.style,
            author: manifest.author,
            canvas: manifest.canvas,
            animations: animations,
            rootURL: rootURL
        )
    }

    private func frameURLs(in directory: URL) throws -> [URL] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        return urls
            .filter { $0.pathExtension.lowercased() == "png" }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
}
