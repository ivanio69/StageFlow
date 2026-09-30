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

    private var carriedNotes: [RehearsalNote] {
        production.rehearsals
            .sorted(by: { $0.scheduledStart > $1.scheduledStart })
            .first?
            .notes
            .filter { $0.carryForward } ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Репетиция") {
                    TextField("Название", text: $title)
                    DatePicker("Начало", selection: $start)
                    DatePicker("Окончание", selection: $end, in: start...)
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
                }
            }
        }
    }

    private func createRehearsal() {
        let rehearsal = Rehearsal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            scheduledStart: start,
            scheduledEnd: end
        )

        modelContext.insert(rehearsal)
        production.rehearsals.append(rehearsal)

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
}
