import Foundation
import SwiftData

@Model
final class Rehearsal {
    var id: UUID = UUID()
    var title: String = "Репетиция"
    var scheduledStart: Date = Date()
    var scheduledEnd: Date = Date().addingTimeInterval(3600)
    var actualStart: Date?
    var actualEnd: Date?

    @Relationship(deleteRule: .cascade)
    var blocks: [RehearsalBlock] = []

    @Relationship(deleteRule: .cascade)
    var notes: [RehearsalNote] = []

    init(title: String, scheduledStart: Date, scheduledEnd: Date) {
        self.title = title
        self.scheduledStart = scheduledStart
        self.scheduledEnd = scheduledEnd
    }

    var sortedBlocks: [RehearsalBlock] {
        blocks.sorted {
            if $0.orderIndex == $1.orderIndex {
                return $0.plannedStart < $1.plannedStart
            }
            return $0.orderIndex < $1.orderIndex
        }
    }

    var isFinished: Bool { actualEnd != nil }
}
