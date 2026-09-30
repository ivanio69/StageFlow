import Foundation
import SwiftData

@Model
final class RehearsalNote {
    var id: UUID = UUID()
    var text: String = ""
    var createdAt: Date = Date()
    var blockID: UUID?
    var carryForward: Bool = false

    init(text: String, blockID: UUID? = nil, carryForward: Bool = false) {
        self.text = text
        self.blockID = blockID
        self.carryForward = carryForward
    }
}
