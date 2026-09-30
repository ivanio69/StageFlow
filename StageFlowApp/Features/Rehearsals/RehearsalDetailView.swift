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
