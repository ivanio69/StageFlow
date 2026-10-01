import SwiftUI
import SwiftData

@main
@MainActor
struct StageFlowApp: App {
    private let modelContainer = StageFlowPersistence.container

    var body: some Scene {
        WindowGroup {
            ProjectsView()
                .preferredColorScheme(.dark)
                .task {
                    PhoneWatchSessionManager.shared.configure(
                        modelContainer: modelContainer
                    )
                }
        }
        .modelContainer(modelContainer)
    }
}
