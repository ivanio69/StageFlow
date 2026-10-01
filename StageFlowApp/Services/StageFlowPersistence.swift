import SwiftData

@MainActor
enum StageFlowPersistence {
    static let container: ModelContainer = {
        let schema = Schema([
            Production.self,
            Rehearsal.self,
            RehearsalBlock.self,
            RehearsalNote.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        return try! ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }()
}
