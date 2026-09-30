import SwiftUI

struct CurrentBlockView: View {
    let snapshot: WatchSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(snapshot.rehearsalTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(snapshot.blockTitle)
                    .font(.title3.bold())
                    .lineLimit(3)

                Text(deltaText)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(deltaColor)

                if let plannedEnd = snapshot.plannedEnd {
                    Label(plannedEnd.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        .font(.footnote)
                }

                if let next = snapshot.nextBlockTitle {
                    Divider()
                    Text("Далее")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(next)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }

    private var deltaText: String {
        let minutes = Int((abs(snapshot.scheduleDeltaSeconds) / 60).rounded())
        guard minutes > 0 else { return "По графику" }
        return snapshot.scheduleDeltaSeconds > 0 ? "+\(minutes) мин" : "−\(minutes) мин"
    }

    private var deltaColor: Color {
        if snapshot.scheduleDeltaSeconds > 30 { return .orange }
        if snapshot.scheduleDeltaSeconds < -30 { return .green }
        return .secondary
    }
}
