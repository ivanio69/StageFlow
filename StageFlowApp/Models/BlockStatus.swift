import Foundation

enum BlockStatus: String, Codable, CaseIterable {
    case planned
    case running
    case completed
    case skipped
    case cancelled

    var title: String {
        switch self {
        case .planned: "Не начато"
        case .running: "Идёт"
        case .completed: "Завершено"
        case .skipped: "Пропущено"
        case .cancelled: "Отменено"
        }
    }
}
