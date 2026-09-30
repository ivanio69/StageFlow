import SwiftUI
import SwiftData

struct AddRehearsalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let production: Production

    @State private var title = "Репетиция"
    @State private var start = Date()
    @State private var end = Date().addingTimeInterval(2 * 3600)

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название", text: $title)
                DatePicker("Начало", selection: $start)
                DatePicker("Окончание", selection: $end, in: start...)
            }
            .navigationTitle("Новая репетиция")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        let rehearsal = Rehearsal(title: title, scheduledStart: start, scheduledEnd: end)
                        production.rehearsals.append(rehearsal)
                        modelContext.insert(rehearsal)
                        dismiss()
                    }
                }
            }
        }
    }
}
