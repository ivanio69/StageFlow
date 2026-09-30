import Foundation
import SwiftData
import WatchConnectivity

@MainActor
final class PhoneWatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchSessionManager()

    private var modelContainer: ModelContainer?

    private override init() {
        super.init()
    }

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sync(rehearsal: Rehearsal) {
        guard WCSession.isSupported() else { return }

        let payload = snapshotPayload(for: rehearsal)

        do {
            try WCSession.default.updateApplicationContext(payload)
        } catch {
            print("Watch sync failed: \(error.localizedDescription)")
        }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }

    private func snapshotPayload(for rehearsal: Rehearsal) -> [String: Any] {
        let current = ScheduleEngine.currentBlock(in: rehearsal)
        let next = ScheduleEngine.nextBlock(in: rehearsal)

        let mode: WatchSnapshotMode
        if current != nil {
            mode = .running
        } else if next != nil {
            mode = .ready
        } else if rehearsal.blocks.isEmpty {
            mode = .idle
        } else {
            mode = .finished
        }

        let snapshot = WatchSnapshot(
            rehearsalID: rehearsal.id,
            rehearsalTitle: rehearsal.title,
            blockID: current?.id,
            blockTitle: current?.title ?? next?.title ?? (rehearsal.blocks.isEmpty ? "График пуст" : "На сегодня всё"),
            plannedStart: current?.plannedStart ?? next?.plannedStart,
            plannedEnd: current?.plannedEnd ?? next?.plannedEnd,
            actualStart: current?.actualStart,
            scheduleDeltaSeconds: ScheduleEngine.scheduleDelta(in: rehearsal),
            predictedFinish: ScheduleEngine.predictedFinish(in: rehearsal),
            nextBlockTitle: current.flatMap { running in
                rehearsal.sortedBlocks.first(where: {
                    $0.orderIndex > running.orderIndex && $0.status == .planned
                })?.title
            },
            mode: mode
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return [:] }
        return ["snapshot": data]
    }

    private func process(_ command: WatchCommand) async {
        guard let modelContainer else { return }

        let context = modelContainer.mainContext
        guard let rehearsals = try? context.fetch(FetchDescriptor<Rehearsal>()),
              let rehearsal = rehearsals.first(where: { $0.id == command.rehearsalID }) else {
            return
        }

        switch command.action {
        case .startNextBlock:
            guard ScheduleEngine.currentBlock(in: rehearsal) == nil,
                  let next = ScheduleEngine.nextBlock(in: rehearsal) else {
                return
            }

            let now = Date()
            if rehearsal.actualStart == nil {
                rehearsal.actualStart = now
            }
            next.actualStart = now
            next.status = .running

        case .finishCurrentBlock:
            guard let current = ScheduleEngine.currentBlock(in: rehearsal) else {
                return
            }

            let now = Date()
            current.actualEnd = now
            current.status = .completed

            if ScheduleEngine.nextBlock(in: rehearsal) == nil {
                rehearsal.actualEnd = now
            }

        case .addNote:
            let text = command.text?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !text.isEmpty else { return }

            rehearsal.notes.append(
                RehearsalNote(
                    text: text,
                    blockID: ScheduleEngine.currentBlock(in: rehearsal)?.id
                )
            )
        }

        try? context.save()
        sync(rehearsal: rehearsal)

        switch command.action {
        case .startNextBlock:
            await LiveActivityManager.shared.startOrUpdate(rehearsal: rehearsal)

        case .finishCurrentBlock:
            if ScheduleEngine.nextBlock(in: rehearsal) == nil {
                await LiveActivityManager.shared.end(rehearsal: rehearsal)
            } else {
                await LiveActivityManager.shared.startOrUpdate(rehearsal: rehearsal)
            }

        case .addNote:
            break
        }
    }

    nonisolated private func decodeCommand(from payload: [String: Any]) -> WatchCommand? {
        guard let data = payload["command"] as? Data else { return nil }
        return try? JSONDecoder().decode(WatchCommand.self, from: data)
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let command = decodeCommand(from: message) else { return }
        Task { @MainActor in
            await process(command)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let command = decodeCommand(from: userInfo) else { return }
        Task { @MainActor in
            await process(command)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
