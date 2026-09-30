import Foundation

enum WatchCommandAction: String, Codable {
    case startNextBlock
    case finishCurrentBlock
    case skipNextBlock
    case addNote
}

struct WatchCommand: Codable {
    let id: UUID
    let rehearsalID: UUID
    let action: WatchCommandAction
    let text: String?
    let createdAt: Date

    init(rehearsalID: UUID, action: WatchCommandAction, text: String? = nil) {
        self.id = UUID()
        self.rehearsalID = rehearsalID
        self.action = action
        self.text = text
        self.createdAt = Date()
    }
}
