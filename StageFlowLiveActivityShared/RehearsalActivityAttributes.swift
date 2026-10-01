import ActivityKit
import Foundation

struct RehearsalActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var blockTitle: String
        var plannedStart: Date?
        var plannedEnd: Date?
        var actualStart: Date?
        var scheduleDeltaSeconds: TimeInterval
        var predictedFinish: Date?
        var nextBlockTitle: String?
        var nextBlockStart: Date?
        var isRunning: Bool
        var isFinished: Bool
    }

    let rehearsalID: UUID
    let rehearsalTitle: String
}
