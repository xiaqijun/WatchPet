import Foundation
import WatchConnectivity

@MainActor
final class CompanionWatchSyncManager: NSObject, ObservableObject {
    @Published private(set) var isSupported = WCSession.isSupported()
    @Published private(set) var isPaired = false
    @Published private(set) var isWatchAppInstalled = false
    @Published private(set) var isReachable = false
    @Published private(set) var pendingFileTransfers = 0
    @Published private(set) var lastStatusMessage = "Ready"

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    override init() {
        super.init()
        activate()
    }

    func activate() {
        guard let session else {
            lastStatusMessage = "WatchConnectivity is not supported"
            return
        }
        session.delegate = self
        session.activate()
        refreshSessionState(session)
    }

    func send(package: PetPackage, selectedAction: PetAction) {
        sendMetadata(package: package, selectedAction: selectedAction)
        transferResources(package: package, selectedAction: selectedAction)
    }

    func sendMetadata(package: PetPackage, selectedAction: PetAction) {
        guard let session else {
            lastStatusMessage = "This device does not support WatchConnectivity"
            return
        }

        let payload = metadataPayload(package: package, selectedAction: selectedAction)

        do {
            try session.updateApplicationContext(payload)
            lastStatusMessage = "Queued metadata for \(package.name)"
        } catch {
            lastStatusMessage = "Failed to queue metadata: \(error.localizedDescription)"
        }

        guard session.isReachable else { return }
        session.sendMessage(payload, replyHandler: { [weak self] reply in
            Task { @MainActor in
                let ok = (reply["ok"] as? Bool) == true
                self?.lastStatusMessage = ok ? "Queued metadata for \(package.name)" : "Watch reply was not OK"
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor in
                self?.lastStatusMessage = "Transfer failed: \(error.localizedDescription)"
            }
        })
    }

    func transferResources(package: PetPackage, selectedAction: PetAction) {
        guard let session else {
            lastStatusMessage = "This device does not support WatchConnectivity"
            return
        }

        do {
            let files = try packageTransferFiles(package: package)
            guard !files.isEmpty else {
                lastStatusMessage = "No package files found to transfer"
                return
            }

            for item in files {
                var metadata = metadataPayload(package: package, selectedAction: selectedAction)
                metadata["kind"] = "watchpet.package.file"
                metadata["relativePath"] = item.relativePath
                metadata["fileName"] = item.url.lastPathComponent
                session.transferFile(item.url, metadata: metadata)
            }
            pendingFileTransfers = session.outstandingFileTransfers.count
            lastStatusMessage = "Queued \(files.count) package files"
        } catch {
            lastStatusMessage = "Transfer failed: \(error.localizedDescription)"
        }
    }

    private func metadataPayload(package: PetPackage, selectedAction: PetAction) -> [String: Any] {
        [
            "kind": "watchpet.package.selection",
            "packageId": package.id,
            "name": package.name,
            "species": package.species,
            "style": package.style,
            "selectedAction": selectedAction.rawValue,
            "sentAt": Date().timeIntervalSince1970
        ]
    }

    private func packageTransferFiles(package: PetPackage) throws -> [(url: URL, relativePath: String)] {
        let root = package.rootURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return []
        }

        let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var files: [(URL, String)] = []
        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: Set(resourceKeys))
            guard values.isRegularFile == true else { continue }
            let relativePath = url.path.replacingOccurrences(of: root.path + "/", with: "")
            guard relativePath == "manifest.json" || relativePath.hasSuffix(".png") else { continue }
            files.append((url, relativePath))
        }
        return files.sorted { lhs, rhs in lhs.1.localizedStandardCompare(rhs.1) == .orderedAscending }
    }

    private func refreshSessionState(_ session: WCSession) {
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        isReachable = session.isReachable
        pendingFileTransfers = session.outstandingFileTransfers.count
    }
}

extension CompanionWatchSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.refreshSessionState(session)
            if let error {
                self.lastStatusMessage = "WatchConnectivity activation failed: \(error.localizedDescription)"
            } else {
                self.lastStatusMessage = "WatchConnectivity activated: \(activationState.rawValue)"
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshSessionState(session)
        }
    }

    nonisolated func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        Task { @MainActor in
            self.refreshSessionState(session)
            if let error {
                self.lastStatusMessage = "Transfer failed: \(error.localizedDescription)"
            } else {
                self.lastStatusMessage = "File transfer finished; pending \(session.outstandingFileTransfers.count)"
            }
        }
    }
}
