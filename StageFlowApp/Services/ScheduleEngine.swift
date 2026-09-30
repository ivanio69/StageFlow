import Foundation

struct ScheduleEngine {
    static func currentBlock(in rehearsal: Rehearsal) -> RehearsalBlock? {
        rehearsal.sortedBlocks.first(where: { $0.status == .running })
    }

    static func nextBlock(in rehearsal: Rehearsal) -> RehearsalBlock? {
        rehearsal.sortedBlocks.first(where: { $0.status == .planned })
    }

    static func scheduleDelta(in rehearsal: Rehearsal, now: Date = Date()) -> TimeInterval {
        if let running = currentBlock(in: rehearsal), let actualStart = running.actualStart {
            let predictedBlockEnd = actualStart.addingTimeInterval(running.plannedDuration)
            let effectiveEnd = max(predictedBlockEnd, now)
            return effectiveEnd.timeIntervalSince(running.plannedEnd)
        }

        if let lastCompleted = rehearsal.sortedBlocks
            .filter({ $0.status == .completed && $0.actualEnd != nil })
            .last,
           let actualEnd = lastCompleted.actualEnd {
            return actualEnd.timeIntervalSince(lastCompleted.plannedEnd)
        }

        if let next = nextBlock(in: rehearsal), now > next.plannedStart {
            return now.timeIntervalSince(next.plannedStart)
        }

        return 0
    }

    static func predictedFinish(in rehearsal: Rehearsal, now: Date = Date()) -> Date {
        rehearsal.scheduledEnd.addingTimeInterval(scheduleDelta(in: rehearsal, now: now))
    }

    static func formattedDelta(_ seconds: TimeInterval) -> String {
        let roundedMinutes = Int((abs(seconds) / 60).rounded())
        if roundedMinutes == 0 { return "по графику" }
        return seconds > 0 ? "+\(roundedMinutes) мин" : "−\(roundedMinutes) мин"
    }
}
