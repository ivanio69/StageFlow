import SwiftUI

@main
struct StageFlowWatchApp: App {
    @State private var session = WatchSessionManager()

    var body: some Scene {
        WindowGroup {
            CurrentBlockView(session: session)
        }
    }
}
