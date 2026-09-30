import Foundation
import WatchConnectivity

@MainActor
final class PhoneWatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchSessionManager()

    private override init() {
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sync(rehearsal: Rehearsal) {
        guard WCSession.isSupported() else { return }

        let current = ScheduleEngine.currentBlock(in: rehearsal)
        let next = ScheduleEngine.nextBlock(in: rehearsal)
        let snapshot = WatchSnapshot(
            rehearsalID: rehearsal.id,
            rehearsalTitle: rehearsal.title,
            blockID: current?.id,
            blockTitle: current?.title ?? next?.title ?? "На сегодня всё",
            plannedStart: current?.plannedStart ?? next?.plannedStart,
            plannedEnd: current?.plannedEnd ?? next?.plannedEnd,
            actualStart: current?.actualStart,
            scheduleDeltaSeconds: ScheduleEngine.scheduleDelta(in: rehearsal),
            predictedFinish: ScheduleEngine.predictedFinish(in: rehearsal),
            nextBlockTitle: current.flatMap { running in
                rehearsal.sortedBlocks.first(where: { $0.orderIndex > running.orderIndex && $0.status == .planned })?.title
            }
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        let payload: [String: Any] = ["snapshot": data]

        do {
            try WCSession.default.updateApplicationContext(payload)
        } catch {
            print("Watch sync failed: \(error.localizedDescription)")
        }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
