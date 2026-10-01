import AppIntents
import Foundation

struct AdvanceRehearsalIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Дальше"
    static var description = IntentDescription(
        "Завершает текущий блок и запускает следующий."
    )

    @Parameter(title: "Rehearsal ID")
    var rehearsalID: String

    init() {
        rehearsalID = ""
    }

    init(rehearsalID: String) {
        self.rehearsalID = rehearsalID
    }

    func perform() async throws -> some IntentResult {
#if LIVE_ACTIVITY_EXTENSION
        return .result()
#else
        await RehearsalIntentController.advance(
            rehearsalID: rehearsalID
        )
        return .result()
#endif
    }
}
