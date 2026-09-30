import SwiftUI

struct RehearsalSummaryView: View {
    let rehearsal: Rehearsal

    private var plannedDuration: TimeInterval {
        max(0, rehearsal.scheduledEnd.timeIntervalSince(rehearsal.scheduledStart))
    }

    private var actualDuration: TimeInterval? {
        guard let start = rehearsal.actualStart else { return nil }
        let end = rehearsal.actualEnd ?? Date()
        return max(0, end.timeIntervalSince(start))
    }

    private var finalDelta: TimeInterval {
        if let actualEnd = rehearsal.actualEnd {
            return actualEnd.timeIntervalSince(rehearsal.scheduledEnd)
        }
        return ScheduleEngine.scheduleDelta(in: rehearsal)
    }

    private var completedBlocks: [RehearsalBlock] {
        rehearsal.sortedBlocks.filter {
            $0.status == .completed && $0.actualStart != nil && $0.actualEnd != nil
        }
    }

    private var blockResults: [(block: RehearsalBlock, delta: TimeInterval)] {
        completedBlocks.compactMap { block in
            guard let actualStart = block.actualStart,
                  let actualEnd = block.actualEnd else {
                return nil
            }

            let actual = actualEnd.timeIntervalSince(actualStart)
            return (block, actual - block.plannedDuration)
        }
        .sorted { abs($0.delta) > abs($1.delta) }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    metric(
                        title: "План",
                        value: durationText(plannedDuration),
                        systemImage: "calendar"
                    )

                    metric(
                        title: rehearsal.isFinished ? "Факт" : "Прошло",
                        value: actualDuration.map(durationText) ?? "—",
                        systemImage: "clock"
                    )
                }

                HStack(spacing: 12) {
                    metric(
                        title: "Отклонение",
                        value: ScheduleEngine.formattedDelta(finalDelta),
                        systemImage: finalDelta > 30
                            ? "exclamationmark.circle"
                            : "checkmark.circle"
                    )

                    metric(
                        title: "Блоки",
                        value: "\(completedBlocks.count)/\(rehearsal.blocks.count)",
                        systemImage: "list.bullet"
                    )
                }
            }

            if !blockResults.isEmpty {
                Section("Блоки по времени") {
                    ForEach(Array(blockResults.prefix(5)), id: \.block.id) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.block.title)
                                    .font(.headline)

                                Text(
                                    "План \(durationText(item.block.plannedDuration))"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(deltaDurationText(item.delta))
                                .font(.subheadline.bold().monospacedDigit())
                                .foregroundStyle(deltaColor(item.delta))
                        }
                        .padding(.vertical, 3)
                    }
                }
            }

            Section("Заметки") {
                LabeledContent("Всего", value: "\(rehearsal.notes.count)")

                let carried = rehearsal.notes.filter(\.carryForward).count
                if carried > 0 {
                    LabeledContent("На следующую репетицию", value: "\(carried)")
                }

                if rehearsal.notes.isEmpty {
                    Text("Заметок нет")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(
                        rehearsal.notes.sorted(by: { $0.createdAt < $1.createdAt })
                    ) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.text)

                            HStack(spacing: 8) {
                                Text(
                                    note.createdAt.formatted(
                                        date: .omitted,
                                        time: .shortened
                                    )
                                )

                                if let blockID = note.blockID,
                                   let block = rehearsal.blocks.first(where: {
                                       $0.id == blockID
                                   }) {
                                    Text("·")
                                    Text(block.title)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(rehearsal.isFinished ? "Итоги" : "Сводка")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metric(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int((seconds / 60).rounded()))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours) ч \(minutes) мин"
        } else if hours > 0 {
            return "\(hours) ч"
        } else {
            return "\(minutes) мин"
        }
    }

    private func deltaDurationText(_ seconds: TimeInterval) -> String {
        let minutes = Int((abs(seconds) / 60).rounded())
        guard minutes > 0 else { return "по плану" }
        return seconds > 0 ? "+\(minutes) мин" : "−\(minutes) мин"
    }

    private func deltaColor(_ seconds: TimeInterval) -> Color {
        if seconds > 30 { return .orange }
        if seconds < -30 { return .green }
        return .secondary
    }
}
