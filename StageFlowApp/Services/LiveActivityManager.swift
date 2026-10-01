import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private init() {}

    func startOrUpdate(
        rehearsal: Rehearsal,
        now: Date = Date()
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let state = contentState(
            for: rehearsal,
            now: now
        )

        let content = ActivityContent(
            state: state,
            staleDate: now.addingTimeInterval(5 * 60)
        )

        if let activity = activity(for: rehearsal.id) {
            nonisolated(unsafe) let activeActivity = activity
            await activeActivity.update(content)
            return
        }

        let attributes = RehearsalActivityAttributes(
            rehearsalID: rehearsal.id,
            rehearsalTitle: rehearsal.title
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: content
            )
        } catch {
            print(
                "Live Activity start failed: \(error.localizedDescription)"
            )
        }
    }

    func end(
        rehearsal: Rehearsal,
        now: Date = Date()
    ) async {
        guard let activity = activity(for: rehearsal.id) else {
            return
        }

        let state = contentState(
            for: rehearsal,
            now: now,
            forceFinished: true
        )

        let content = ActivityContent(
            state: state,
            staleDate: nil
        )

        nonisolated(unsafe) let activeActivity = activity

        await activeActivity.end(
            content,
            dismissalPolicy: .after(
                Date().addingTimeInterval(15 * 60)
            )
        )
    }

    private func activity(
        for rehearsalID: UUID
    ) -> Activity<RehearsalActivityAttributes>? {
        Activity<RehearsalActivityAttributes>
            .activities
            .first(where: {
                $0.attributes.rehearsalID == rehearsalID
            })
    }

    private func contentState(
        for rehearsal: Rehearsal,
        now: Date,
        forceFinished: Bool = false
    ) -> RehearsalActivityAttributes.ContentState {
        let current = ScheduleEngine.currentBlock(
            in: rehearsal
        )

        let next = ScheduleEngine.nextBlock(
            in: rehearsal
        )

        let displayed = current ?? next

        let following = displayed.flatMap { displayedBlock in
            rehearsal.sortedBlocks.first(where: {
                $0.orderIndex > displayedBlock.orderIndex
                    && $0.status == .planned
            })
        }

        let isFinished = forceFinished
            || (current == nil && next == nil)

        let nextStart = following.map {
            ScheduleEngine.projectedStart(
                for: $0,
                in: rehearsal,
                now: now
            )
        }

        return .init(
            blockTitle: displayed?.title
                ?? "На сегодня всё",
            plannedStart: displayed?.plannedStart,
            plannedEnd: displayed?.plannedEnd,
            actualStart: current?.actualStart,
            scheduleDeltaSeconds: ScheduleEngine.scheduleDelta(
                in: rehearsal,
                now: now
            ),
            predictedFinish: isFinished
                ? rehearsal.actualEnd
                : ScheduleEngine.predictedFinish(
                    in: rehearsal,
                    now: now
                ),
            nextBlockTitle: following?.title,
            nextBlockStart: nextStart,
            isRunning: current != nil,
            isFinished: isFinished
        )
    }
}
