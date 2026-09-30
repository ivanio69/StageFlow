import ActivityKit
import Foundation

struct RehearsalActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var blockTitle: String
        var plannedStart: Date?
        var plannedEnd: Date?
        var scheduleDeltaSeconds: TimeInterval
        var predictedFinish: Date?
        var nextBlockTitle: String?
        var isFinished: Bool
    }

    let rehearsalID: UUID
    let rehearsalTitle: String
}
