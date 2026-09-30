import Foundation
import SwiftData

@Model
final class Production {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade)
    var rehearsals: [Rehearsal] = []

    init(title: String) {
        self.title = title
    }
}
