import Foundation
import WatchConnectivity

struct SyncedPetPackage: Equatable {
    let id: String
    let name: String
    let species: String
    let style: String
    let selectedAction: String
    let receivedAt: Date
}

@MainActor
final class WatchCompanionSyncManager: NSObject, ObservableObject {
    @Published private(set) var activationState: WCSessionActivationState = .notActivated
    @Published private(set) var isReachable = false
    @Published private(set) var syncedPackage: SyncedPetPackage?
    @Published private(set) var importedPackage: ImportedPetPackage?
    @Published private(set) var receivedFileCount = 0
    @Published private(set) var lastStatusMessage = "Waiting for iPhone"

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    override init() {
        super.init()
        importedPackage = WatchPetResourceStore.loadLatestPackage()
        if let importedPackage {
            syncedPackage = SyncedPetPackage(
                id: importedPackage.id,
                name: importedPackage.name,
                species: importedPackage.species,
                style: importedPackage.style,
                selectedAction: "idle",
                receivedAt: Date()
            )
            lastStatusMessage = "Loaded imported pet: \(importedPackage.name)"
        }
        activate()
    }

    func activate() {
        guard let session else {
            lastStatusMessage = "WatchConnectivity is not supported"
            return
        }
        session.delegate = self
        session.activate()
    }

    private func apply(message: [String: Any]) {
        guard (message["kind"] as? String) == "watchpet.package.selection" else { return }
        guard let id = message["packageId"] as? String,
              let name = message["name"] as? String,
              let species = message["species"] as? String,
              let style = message["style"] as? String else {
            lastStatusMessage = "Invalid package payload"
            return
        }
        let selectedAction = message["selectedAction"] as? String ?? "idle"
        syncedPackage = SyncedPetPackage(
            id: id,
            name: name,
            species: species,
            style: style,
            selectedAction: selectedAction,
            receivedAt: Date()
        )
        lastStatusMessage = "Selected pet: \(name)"
    }

    private func apply(imported package: ImportedPetPackage?) {
        guard let package else { return }
        importedPackage = package
        syncedPackage = SyncedPetPackage(
            id: package.id,
            name: package.name,
            species: package.species,
            style: package.style,
            selectedAction: syncedPackage?.selectedAction ?? "idle",
            receivedAt: Date()
        )
        lastStatusMessage = "Imported resources: \(package.name)"
    }
}

extension WatchCompanionSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.activationState = activationState
            self.isReachable = session.isReachable
            if let error {
                self.lastStatusMessage = "Activation failed: \(error.localizedDescription)"
            } else if activationState == .activated {
                self.lastStatusMessage = self.importedPackage == nil ? "WatchConnectivity activated" : self.lastStatusMessage
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.apply(message: applicationContext)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            self.apply(message: message)
            replyHandler(["ok": true])
        }
    }

    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let imported = try? WatchPetResourceStore.saveTransferredFile(sourceURL: file.fileURL, metadata: file.metadata)
        Task { @MainActor in
            self.receivedFileCount += 1
            if let imported {
                self.apply(imported: imported)
            } else {
                self.lastStatusMessage = "Received package file #\(self.receivedFileCount)"
            }
        }
    }
}
