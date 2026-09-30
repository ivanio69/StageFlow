import Foundation
import Observation
import WatchConnectivity
import WatchKit

@MainActor
@Observable
final class WatchSessionManager: NSObject, WCSessionDelegate {
    var snapshot: WatchSnapshot = .empty
    var isPhoneReachable = false
    var statusMessage: String?

    override init() {
        super.init()

        guard WCSession.isSupported() else { return }

        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func startNextBlock() {
        send(
            WatchCommand(
                rehearsalID: snapshot.rehearsalID,
                action: .startNextBlock
            )
        )
    }

    func finishCurrentBlock() {
        send(
            WatchCommand(
                rehearsalID: snapshot.rehearsalID,
                action: .finishCurrentBlock
            )
        )
    }

    func skipNextBlock() {
        send(
            WatchCommand(
                rehearsalID: snapshot.rehearsalID,
                action: .skipNextBlock
            )
        )
    }

    func addNote(_ text: String) {
        let trimmed = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else { return }

        send(
            WatchCommand(
                rehearsalID: snapshot.rehearsalID,
                action: .addNote,
                text: trimmed
            ),
            allowQueuedDelivery: true
        )
    }

    private func send(
        _ command: WatchCommand,
        allowQueuedDelivery: Bool = false
    ) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(command) else {
            statusMessage = "Связь недоступна"
            return
        }

        let payload: [String: Any] = ["command": data]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                payload,
                replyHandler: nil,
                errorHandler: { [weak self] _ in
                    Task { @MainActor in
                        self?.statusMessage = "Не удалось отправить"
                        WKInterfaceDevice.current().play(.failure)
                    }
                }
            )

            statusMessage = "Отправлено"
            WKInterfaceDevice.current().play(.click)
            return
        }

        if allowQueuedDelivery {
            WCSession.default.transferUserInfo(payload)
            statusMessage = "Заметка в очереди"
            WKInterfaceDevice.current().play(.click)
        } else {
            statusMessage = "iPhone недоступен"
            WKInterfaceDevice.current().play(.failure)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if !session.applicationContext.isEmpty {
            handle(session.applicationContext)
        }

        Task { @MainActor in
            isPhoneReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(
        _ session: WCSession
    ) {
        Task { @MainActor in
            isPhoneReachable = session.isReachable
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        handle(applicationContext)
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        handle(message)
    }

    nonisolated private func handle(
        _ payload: [String: Any]
    ) {
        guard let data = payload["snapshot"] as? Data,
              let decoded = try? JSONDecoder().decode(
                WatchSnapshot.self,
                from: data
              ) else {
            return
        }

        Task { @MainActor in
            snapshot = decoded
            statusMessage = nil
        }
    }
}
