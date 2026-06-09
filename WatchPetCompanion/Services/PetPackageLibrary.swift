import Foundation
import ZIPFoundation

@MainActor
final class PetPackageLibrary: ObservableObject {
    @Published private(set) var packages: [PetPackage] = []
    @Published private(set) var lastMessage = "Ready"

    private let loader = WatchPetPackageLoader.shared

    func loadBundledSample() throws -> PetPackage {
        let package = try loader.loadBundledSample()
        upsert(package)
        lastMessage = "Loaded bundled sample: \(package.name)"
        return package
    }

    func importPackage(from url: URL) throws -> PetPackage {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return try importUnpackedPackage(fromSecurityScopedURL: url)
        }
        return try importArchivePackage(fromSecurityScopedURL: url)
    }

    func importUnpackedPackage(from url: URL) throws -> PetPackage {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }
        return try importUnpackedPackage(fromSecurityScopedURL: url)
    }

    private func importUnpackedPackage(fromSecurityScopedURL url: URL) throws -> PetPackage {
        let package = try loader.loadUnpackedPackage(at: url)
        upsert(package)
        lastMessage = "Imported folder package: \(package.name)"
        return package
    }

    private func importArchivePackage(fromSecurityScopedURL url: URL) throws -> PetPackage {
        let destination = try makeImportDirectory(for: url)
        try FileManager.default.unzipItem(at: url, to: destination)

        let root = try normalizedPackageRoot(in: destination)
        let package = try loader.loadUnpackedPackage(at: root)
        upsert(package)
        lastMessage = "Imported .watchpet archive: \(package.name)"
        return package
    }

    private func makeImportDirectory(for sourceURL: URL) throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = base.appendingPathComponent("ImportedWatchPetPackages", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let name = sourceURL.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        let destination = root.appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        return destination
    }

    private func normalizedPackageRoot(in destination: URL) throws -> URL {
        let manifestAtRoot = destination.appendingPathComponent("manifest.json")
        if FileManager.default.fileExists(atPath: manifestAtRoot.path) {
            return destination
        }

        let children = try FileManager.default.contentsOfDirectory(
            at: destination,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        let packageFolders = children.filter { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            guard values?.isDirectory == true else { return false }
            return FileManager.default.fileExists(atPath: url.appendingPathComponent("manifest.json").path)
        }
        if let onlyPackageFolder = packageFolders.first, packageFolders.count == 1 {
            return onlyPackageFolder
        }
        return destination
    }

    private func upsert(_ package: PetPackage) {
        packages.removeAll { $0.id == package.id }
        packages.insert(package, at: 0)
    }
}
