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
    @Published private(set) var lastStatusMessage = "等待 iPhone 同步"

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    override init() {
        super.init()
        activate()
    }

    func activate() {
        guard let session else {
            lastStatusMessage = "当前手表不支持 WatchConnectivity"
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
            lastStatusMessage = "收到的数据不完整"
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
        lastStatusMessage = "已接收：\(name)"
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
                self.lastStatusMessage = "同步启动失败：\(error.localizedDescription)"
            } else if activationState == .activated {
                self.lastStatusMessage = "已连接同步通道"
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
}
