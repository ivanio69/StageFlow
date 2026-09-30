import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private init() {}

    private var activity: Activity<RehearsalActivityAttributes>? {
        Activity<RehearsalActivityAttributes>.activities.first
    }

    func startOrUpdate(rehearsal: Rehearsal, now: Date = Date()) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = contentState(for: rehearsal, now: now)
        let content = ActivityContent(state: state, staleDate: now.addingTimeInterval(120))

        if let activity {
            await activity.update(content)
            return
        }

        let attributes = RehearsalActivityAttributes(
            rehearsalID: rehearsal.id,
            rehearsalTitle: rehearsal.title
        )

        do {
            _ = try Activity.request(attributes: attributes, content: content)
        } catch {
            print("Live Activity start failed: \(error.localizedDescription)")
        }
    }

    func end(rehearsal: Rehearsal, now: Date = Date()) async {
        guard let activity else { return }
        let state = contentState(for: rehearsal, now: now, forceFinished: true)
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(15 * 60)))
    }

    private func contentState(
        for rehearsal: Rehearsal,
        now: Date,
        forceFinished: Bool = false
    ) -> RehearsalActivityAttributes.ContentState {
        let current = ScheduleEngine.currentBlock(in: rehearsal)
        let next = ScheduleEngine.nextBlock(in: rehearsal)
        let isFinished = forceFinished || (current == nil && next == nil)

        return .init(
            blockTitle: current?.title ?? next?.title ?? "На сегодня всё",
            plannedStart: current?.plannedStart ?? next?.plannedStart,
            plannedEnd: current?.plannedEnd ?? next?.plannedEnd,
            scheduleDeltaSeconds: ScheduleEngine.scheduleDelta(in: rehearsal, now: now),
            predictedFinish: ScheduleEngine.predictedFinish(in: rehearsal, now: now),
            nextBlockTitle: current.flatMap { running in
                rehearsal.sortedBlocks.first(where: {
                    $0.orderIndex > running.orderIndex && $0.status == .planned
                })?.title
            },
            isFinished: isFinished
        )
    }
}
