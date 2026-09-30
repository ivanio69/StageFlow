import SwiftUI

struct RehearsalDetailView: View {
    let rehearsal: Rehearsal
    @State private var showingEditor = false
    @State private var showingRunMode = false
    @State private var noteText = ""

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
                            Text("Прогноз финиша")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(ScheduleEngine.predictedFinish(in: rehearsal).formatted(date: .omitted, time: .shortened))
                                .font(.headline)
                        }
                    }

                    Button {
                        showingRunMode = true
                    } label: {
                        Label("Открыть пульт репетиции", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 6)
            }

            Section("График") {
                if rehearsal.sortedBlocks.isEmpty {
                    Text("Добавьте блоки графика")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rehearsal.sortedBlocks) { block in
                        BlockRow(block: block)
                    }
                }
            }

            Section("Заметки") {
                HStack {
                    TextField("Быстрая заметка", text: $noteText, axis: .vertical)
                    Button("Добавить", systemImage: "plus.circle.fill") {
                        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        rehearsal.notes.append(RehearsalNote(text: trimmed))
                        noteText = ""
                    }
                    .labelStyle(.iconOnly)
                }

                ForEach(rehearsal.notes.sorted(by: { $0.createdAt > $1.createdAt })) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.text)
                        Text(note.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
    }
}
