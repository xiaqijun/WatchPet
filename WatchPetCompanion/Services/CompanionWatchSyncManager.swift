import Foundation
import WatchConnectivity

@MainActor
final class CompanionWatchSyncManager: NSObject, ObservableObject {
    @Published private(set) var isSupported = WCSession.isSupported()
    @Published private(set) var isPaired = false
    @Published private(set) var isWatchAppInstalled = false
    @Published private(set) var isReachable = false
    @Published private(set) var lastStatusMessage = "尚未同步"

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    override init() {
        super.init()
        activate()
    }

    func activate() {
        guard let session else {
            lastStatusMessage = "当前设备不支持 WatchConnectivity"
            return
        }
        session.delegate = self
        session.activate()
        refreshSessionState(session)
    }

    func send(package: PetPackage, selectedAction: PetAction) {
        guard let session else {
            lastStatusMessage = "无法同步：设备不支持 WatchConnectivity"
            return
        }

        let payload: [String: Any] = [
            "kind": "watchpet.package.selection",
            "packageId": package.id,
            "name": package.name,
            "species": package.species,
            "style": package.style,
            "selectedAction": selectedAction.rawValue,
            "sentAt": Date().timeIntervalSince1970
        ]

        do {
            try session.updateApplicationContext(payload)
            lastStatusMessage = "已保存同步上下文：\(package.name)"
        } catch {
            lastStatusMessage = "同步上下文失败：\(error.localizedDescription)"
        }

        guard session.isReachable else { return }
        session.sendMessage(payload, replyHandler: { [weak self] reply in
            Task { @MainActor in
                let ok = (reply["ok"] as? Bool) == true
                self?.lastStatusMessage = ok ? "手表已接收：\(package.name)" : "手表回复异常"
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor in
                self?.lastStatusMessage = "实时发送失败：\(error.localizedDescription)"
            }
        })
    }

    private func refreshSessionState(_ session: WCSession) {
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        isReachable = session.isReachable
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
                self.lastStatusMessage = "WatchConnectivity 启动失败：\(error.localizedDescription)"
            } else {
                self.lastStatusMessage = "WatchConnectivity 已启动：\(activationState.rawValue)"
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
}
