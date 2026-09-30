import SwiftUI
import SwiftData

@main
struct StageFlowApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            Production.self,
            Rehearsal.self,
            RehearsalBlock.self,
            RehearsalNote.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            ProjectsView()
                .preferredColorScheme(.dark)
                .task {
                    PhoneWatchSessionManager.shared.configure(modelContainer: modelContainer)
                }
        }
        .modelContainer(modelContainer)
    }
}
