import Foundation
import SwiftData

@MainActor
enum RehearsalIntentController {
    static func advance(rehearsalID: String) async {
        guard let id = UUID(uuidString: rehearsalID) else {
            return
        }

        let container = StageFlowPersistence.container
        let context = container.mainContext

        guard let rehearsals = try? context.fetch(
            FetchDescriptor<Rehearsal>()
        ),
        let rehearsal = rehearsals.first(where: { $0.id == id }) else {
            return
        }

        let now = Date()

        if let current = ScheduleEngine.currentBlock(in: rehearsal) {
            current.actualEnd = now
            current.status = .completed
        }

        if let next = ScheduleEngine.nextBlock(in: rehearsal) {
            if rehearsal.actualStart == nil {
                rehearsal.actualStart = now
            }

            next.actualStart = now
            next.status = .running
            rehearsal.actualEnd = nil
        } else {
            if rehearsal.actualStart == nil {
                rehearsal.actualStart = now
            }

            rehearsal.actualEnd = now
        }

        try? context.save()

        PhoneWatchSessionManager.shared.configure(
            modelContainer: container
        )
        PhoneWatchSessionManager.shared.sync(
            rehearsal: rehearsal
        )

        if ScheduleEngine.currentBlock(in: rehearsal) == nil,
           ScheduleEngine.nextBlock(in: rehearsal) == nil {
            await LiveActivityManager.shared.end(
                rehearsal: rehearsal,
                now: now
            )
        } else {
            await LiveActivityManager.shared.startOrUpdate(
                rehearsal: rehearsal,
                now: now
            )
        }
    }
}
