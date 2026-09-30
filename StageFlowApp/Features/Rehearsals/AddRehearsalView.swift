import SwiftUI
import SwiftData

struct AddRehearsalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let production: Production

    @State private var title = "Репетиция"
    @State private var start = Date()
    @State private var end = Date().addingTimeInterval(2 * 3600)
    @State private var carryPreviousNotes = true
    @State private var copyPreviousSchedule = false

    private var previousRehearsal: Rehearsal? {
        production.rehearsals
            .filter { $0.scheduledStart < start }
            .max(by: { $0.scheduledStart < $1.scheduledStart })
    }

    private var carriedNotes: [RehearsalNote] {
        previousRehearsal?
            .notes
            .filter { $0.carryForward } ?? []
    }

    private var canCopyPreviousSchedule: Bool {
        !(previousRehearsal?.blocks.isEmpty ?? true)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Репетиция") {
                    TextField("Название", text: $title)
                    DatePicker("Начало", selection: $start)
                    DatePicker("Окончание", selection: $end, in: start...)
                }

                if let previousRehearsal,
                   canCopyPreviousSchedule {
                    Section("График") {
                        Toggle(
                            "Взять график прошлой репетиции",
                            isOn: $copyPreviousSchedule
                        )

                        if copyPreviousSchedule {
                            LabeledContent(
                                "Основа",
                                value: previousRehearsal.title
                            )

                            LabeledContent(
                                "Блоков",
                                value: "\(previousRehearsal.blocks.count)"
                            )

                            Text(
                                "Время блоков будет перенесено относительно нового начала. Фактические отметки и статусы не копируются."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                if !carriedNotes.isEmpty {
                    Section("Замечания с прошлой репетиции") {
                        Toggle(
                            "Перенести в новую репетицию",
                            isOn: $carryPreviousNotes
                        )

                        ForEach(carriedNotes) { note in
                            Label(note.text, systemImage: "pin.fill")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Новая репетиция")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        createRehearsal()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
            .onChange(of: start) { _, _ in
                if copyPreviousSchedule {
                    applyTemplateDuration()
                }
            }
            .onChange(of: copyPreviousSchedule) { _, isEnabled in
                if isEnabled {
                    applyTemplateDuration()
                }
            }
        }
    }

    private func createRehearsal() {
        guard !trimmedTitle.isEmpty else { return }

        let rehearsal = Rehearsal(
            title: trimmedTitle,
            scheduledStart: start,
            scheduledEnd: end
        )

        modelContext.insert(rehearsal)
        production.rehearsals.append(rehearsal)

        if copyPreviousSchedule,
           let previousRehearsal {
            copySchedule(
                from: previousRehearsal,
                to: rehearsal
            )
        }

        if carryPreviousNotes {
            for source in carriedNotes {
                let note = RehearsalNote(
                    text: source.text,
                    blockID: nil,
                    carryForward: true
                )

                modelContext.insert(note)
                rehearsal.notes.append(note)
            }
        }

        dismiss()
    }

    private func copySchedule(
        from source: Rehearsal,
        to destination: Rehearsal
    ) {
        for sourceBlock in source.sortedBlocks {
            let startOffset = sourceBlock.plannedStart
                .timeIntervalSince(source.scheduledStart)

            let endOffset = sourceBlock.plannedEnd
                .timeIntervalSince(source.scheduledStart)

            let block = RehearsalBlock(
                title: sourceBlock.title,
                plannedStart: destination.scheduledStart
                    .addingTimeInterval(startOffset),
                plannedEnd: destination.scheduledStart
                    .addingTimeInterval(endOffset),
                orderIndex: sourceBlock.orderIndex
            )

            modelContext.insert(block)
            destination.blocks.append(block)
        }
    }

    private func applyTemplateDuration() {
        guard let previousRehearsal else { return }

        let duration = max(
            0,
            previousRehearsal.scheduledEnd
                .timeIntervalSince(previousRehearsal.scheduledStart)
        )

        end = start.addingTimeInterval(duration)
    }
}
