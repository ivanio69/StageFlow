import SwiftUI

struct ProductionDetailView: View {
    let production: Production
    @State private var isAddingRehearsal = false

    var body: some View {
        List {
            if production.rehearsals.isEmpty {
                ContentUnavailableView(
                    "Нет репетиций",
                    systemImage: "calendar.badge.plus",
                    description: Text(
                        "Добавьте первую репетицию и разбейте её на блоки."
                    )
                )
            } else {
                ForEach(
                    production.rehearsals.sorted(
                        by: { $0.scheduledStart > $1.scheduledStart }
                    )
                ) { rehearsal in
                    NavigationLink {
                        RehearsalDetailView(rehearsal: rehearsal)
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                Text(rehearsal.title)
                                    .font(.headline)

                                Spacer()

                                statusBadge(for: rehearsal)
                            }

                            Text(
                                rehearsal.scheduledStart.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .foregroundStyle(.secondary)
                            .font(.subheadline)

                            if rehearsal.isFinished {
                                HStack(spacing: 6) {
                                    Text("Итог")
                                    Text(
                                        ScheduleEngine.formattedDelta(
                                            (rehearsal.actualEnd ?? rehearsal.scheduledEnd)
                                                .timeIntervalSince(rehearsal.scheduledEnd)
                                        )
                                    )
                                    .fontWeight(.semibold)
                                }
                                .font(.caption)
                                .foregroundStyle(
                                    resultColor(for: rehearsal)
                                )
                            } else if ScheduleEngine.currentBlock(in: rehearsal) != nil {
                                HStack(spacing: 6) {
                                    Text("Сейчас")
                                    Text(
                                        ScheduleEngine.formattedDelta(
                                            ScheduleEngine.scheduleDelta(in: rehearsal)
                                        )
                                    )
                                    .fontWeight(.semibold)
                                }
                                .font(.caption)
                                .foregroundStyle(
                                    liveColor(for: rehearsal)
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(production.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Репетиция", systemImage: "plus") {
                    isAddingRehearsal = true
                }
            }
        }
        .sheet(isPresented: $isAddingRehearsal) {
            AddRehearsalView(production: production)
        }
    }

    @ViewBuilder
    private func statusBadge(for rehearsal: Rehearsal) -> some View {
        let title: String
        let systemImage: String
        let color: Color

        if rehearsal.isFinished {
            title = "Завершена"
            systemImage = "checkmark.circle.fill"
            color = .green
        } else if ScheduleEngine.currentBlock(in: rehearsal) != nil {
            title = "Идёт"
            systemImage = "play.circle.fill"
            color = .orange
        } else {
            title = "Запланирована"
            systemImage = "clock"
            color = .secondary
        }

        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
    }

    private func resultColor(for rehearsal: Rehearsal) -> Color {
        guard let actualEnd = rehearsal.actualEnd else {
            return .secondary
        }

        let delta = actualEnd.timeIntervalSince(rehearsal.scheduledEnd)

        if delta > 30 { return .orange }
        if delta < -30 { return .green }
        return .secondary
    }

    private func liveColor(for rehearsal: Rehearsal) -> Color {
        let delta = ScheduleEngine.scheduleDelta(in: rehearsal)

        if delta > 30 { return .orange }
        if delta < -30 { return .green }
        return .secondary
    }
}
