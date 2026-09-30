import Foundation

enum WatchSnapshotMode: String, Codable, Equatable {
    case idle
    case ready
    case running
    case finished
}

struct WatchSnapshot: Codable, Equatable {
    let rehearsalID: UUID
    let rehearsalTitle: String
    let blockID: UUID?
    let blockTitle: String
    let plannedStart: Date?
    let plannedEnd: Date?
    let actualStart: Date?
    let scheduleDeltaSeconds: TimeInterval
    let predictedFinish: Date?
    let nextBlockTitle: String?
    let mode: WatchSnapshotMode

    static let empty = WatchSnapshot(
        rehearsalID: UUID(),
        rehearsalTitle: "Нет активной репетиции",
        blockID: nil,
        blockTitle: "Откройте репетицию на iPhone",
        plannedStart: nil,
        plannedEnd: nil,
        actualStart: nil,
        scheduleDeltaSeconds: 0,
        predictedFinish: nil,
        nextBlockTitle: nil,
        mode: .idle
    )
}
