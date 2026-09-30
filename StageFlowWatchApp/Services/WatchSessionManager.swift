import Foundation
import WatchConnectivity
import Observation

@MainActor
@Observable
final class WatchSessionManager: NSObject, WCSessionDelegate {
    var snapshot: WatchSnapshot = .empty

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if !session.applicationContext.isEmpty {
            handle(session.applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handle(applicationContext)
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handle(message)
    }

    nonisolated private func handle(_ payload: [String: Any]) {
        guard let data = payload["snapshot"] as? Data,
              let decoded = try? JSONDecoder().decode(WatchSnapshot.self, from: data) else { return }
        Task { @MainActor in
            snapshot = decoded
        }
    }
}
