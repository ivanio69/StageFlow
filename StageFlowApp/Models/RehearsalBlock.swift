import Foundation
import SwiftData

@Model
final class RehearsalBlock {
    var id: UUID = UUID()
    var title: String = "Новый блок"
    var plannedStart: Date = Date()
    var plannedEnd: Date = Date().addingTimeInterval(1800)
    var actualStart: Date?
    var actualEnd: Date?
    var statusRaw: String = BlockStatus.planned.rawValue
    var orderIndex: Int = 0

    init(title: String, plannedStart: Date, plannedEnd: Date, orderIndex: Int) {
        self.title = title
        self.plannedStart = plannedStart
        self.plannedEnd = plannedEnd
        self.orderIndex = orderIndex
    }

    var status: BlockStatus {
        get { BlockStatus(rawValue: statusRaw) ?? .planned }
        set { statusRaw = newValue.rawValue }
    }

    var plannedDuration: TimeInterval {
        max(0, plannedEnd.timeIntervalSince(plannedStart))
    }
}
