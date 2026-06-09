import Foundation

struct WatchPetResourceStore {
    static let packageRootFolder = "ImportedPackages"

    static func packagesRootURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = base.appendingPathComponent(packageRootFolder, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func saveTransferredFile(sourceURL: URL, metadata: [String: Any]?) throws -> ImportedPetPackage? {
        guard let metadata,
              (metadata["kind"] as? String) == "watchpet.package.file",
              let packageId = metadata["packageId"] as? String,
              let relativePath = metadata["relativePath"] as? String else {
            return nil
        }

        let safePackageId = sanitizePathComponent(packageId)
        let safeRelativePath = sanitizeRelativePath(relativePath)
        let root = try packagesRootURL().appendingPathComponent(safePackageId, isDirectory: true)
        let destination = root.appendingPathComponent(safeRelativePath)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)

        return try? loadPackage(id: safePackageId)
    }

    static func loadPackage(id: String) throws -> ImportedPetPackage {
        let root = try packagesRootURL().appendingPathComponent(sanitizePathComponent(id), isDirectory: true)
        return try loadPackage(rootURL: root)
    }

    static func loadLatestPackage() -> ImportedPetPackage? {
        guard let root = try? packagesRootURL(),
              let packageURLs = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
              ) else { return nil }

        let sorted = packageURLs.sorted { lhs, rhs in
            let leftDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rightDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return leftDate > rightDate
        }

        for url in sorted {
            if let package = try? loadPackage(rootURL: url) {
                return package
            }
        }
        return nil
    }

    static func loadPackage(rootURL: URL) throws -> ImportedPetPackage {
        let manifestURL = rootURL.appendingPathComponent("manifest.json")
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(ImportedPetManifest.self, from: data)

        var animations: [PetAction: ImportedPetAnimation] = [:]
        for action in PetAction.allCases {
            guard let spec = manifest.animations[action.rawValue] else { continue }
            let actionURL = rootURL.appendingPathComponent(spec.path, isDirectory: true)
            let frames = (try? FileManager.default.contentsOfDirectory(
                at: actionURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )) ?? []
            let pngFrames = frames
                .filter { $0.pathExtension.lowercased() == "png" }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            guard !pngFrames.isEmpty else { continue }
            animations[action] = ImportedPetAnimation(action: action, fps: spec.fps, loop: spec.loop, frameURLs: pngFrames)
        }

        return ImportedPetPackage(
            id: manifest.id,
            name: manifest.name,
            species: manifest.species,
            style: manifest.style,
            rootURL: rootURL,
            animations: animations
        )
    }

    private static func sanitizePathComponent(_ value: String) -> String {
        value
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: "..", with: "-")
    }

    private static func sanitizeRelativePath(_ value: String) -> String {
        value
            .split(separator: "/")
            .map { sanitizePathComponent(String($0)) }
            .joined(separator: "/")
    }
}
