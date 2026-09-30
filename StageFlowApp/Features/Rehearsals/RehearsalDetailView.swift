import SwiftUI
import SwiftData

struct RehearsalDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let rehearsal: Rehearsal

    @State private var showingEditor = false
    @State private var showingRunMode = false
    @State private var noteText = ""
    @State private var carryNewNote = false

    private var delta: TimeInterval {
        ScheduleEngine.scheduleDelta(in: rehearsal)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        TimeDeltaBadge(seconds: delta)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(rehearsal.isFinished ? "Финиш" : "Прогноз финиша")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(
                                (rehearsal.actualEnd ?? ScheduleEngine.predictedFinish(in: rehearsal))
                                    .formatted(date: .omitted, time: .shortened)
                            )
                            .font(.headline)
                        }
                    }

                    Button {
                        showingRunMode = true
                    } label: {
                        Label(
                            rehearsal.isFinished
                                ? "Открыть завершённую репетицию"
                                : "Открыть пульт репетиции",
                            systemImage: rehearsal.isFinished
                                ? "checkmark.circle"
                                : "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(rehearsal.sortedBlocks.isEmpty)

                    NavigationLink {
                        RehearsalSummaryView(rehearsal: rehearsal)
                    } label: {
                        Label(
                            rehearsal.isFinished ? "Итоги репетиции" : "Текущая сводка",
                            systemImage: "chart.bar.xaxis"
                        )
                    }
                }
                .padding(.vertical, 6)
            }

            Section("График") {
                if rehearsal.sortedBlocks.isEmpty {
                    Text("Добавьте блоки графика")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rehearsal.sortedBlocks) { block in
                        BlockRow(block: block, rehearsal: rehearsal)
                    }
                }
            }

            Section("Заметки") {
                VStack(spacing: 8) {
                    HStack {
                        TextField("Быстрая заметка", text: $noteText, axis: .vertical)

                        Button("Добавить", systemImage: "plus.circle.fill") {
                            addNote()
                        }
                        .labelStyle(.iconOnly)
                        .disabled(
                            noteText.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty
                        )
                    }

                    Toggle(
                        "На следующую репетицию",
                        isOn: $carryNewNote
                    )
                    .font(.caption)
                }

                ForEach(
                    rehearsal.notes.sorted(by: { $0.createdAt > $1.createdAt })
                ) { note in
                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            note.carryForward.toggle()
                        } label: {
                            Image(
                                systemName: note.carryForward
                                    ? "pin.fill"
                                    : "pin"
                            )
                            .foregroundStyle(
                                note.carryForward
                                    ? .orange
                                    : .secondary
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            note.carryForward
                                ? "Не переносить"
                                : "На следующую репетицию"
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.text)

                            HStack(spacing: 6) {
                                Text(
                                    note.createdAt.formatted(
                                        date: .omitted,
                                        time: .shortened
                                    )
                                )

                                if note.carryForward {
                                    Text("· перенести")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            rehearsal.notes.removeAll(where: {
                                $0.id == note.id
                            })
                            modelContext.delete(note)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(rehearsal.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("График", systemImage: "slider.horizontal.3") {
                    showingEditor = true
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            RehearsalEditorView(rehearsal: rehearsal)
        }
        .fullScreenCover(isPresented: $showingRunMode) {
            RehearsalRunView(rehearsal: rehearsal)
        }
        .onAppear {
            PhoneWatchSessionManager.shared.sync(rehearsal: rehearsal)
        }
        .onChange(of: showingEditor) { _, isShowing in
            if !isShowing {
                PhoneWatchSessionManager.shared.sync(rehearsal: rehearsal)
            }
        }
    }

    private func addNote() {
        let trimmed = noteText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else { return }

        let note = RehearsalNote(
            text: trimmed,
            carryForward: carryNewNote
        )

        modelContext.insert(note)
        rehearsal.notes.append(note)

        noteText = ""
        carryNewNote = false
    }
}

struct RehearsalSummaryView: View {
    struct BlockTimingResult: Identifiable {
        let block: RehearsalBlock
        let delta: TimeInterval

        var id: UUID { block.id }
    }

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

    private var blockResults: [BlockTimingResult] {
        completedBlocks.compactMap { block in
            guard let actualStart = block.actualStart,
                  let actualEnd = block.actualEnd else {
                return nil
            }

            let actual = actualEnd.timeIntervalSince(actualStart)
            return BlockTimingResult(
                block: block,
                delta: actual - block.plannedDuration
            )
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
                    ForEach(Array(blockResults.prefix(5))) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.block.title)
                                    .font(.headline)

                                Text("План \(durationText(item.block.plannedDuration))")
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

                let carried = rehearsal.notes.filter { $0.carryForward }.count

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
