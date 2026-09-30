import SwiftUI

struct BlockEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var block: RehearsalBlock

    var body: some View {
        Form {
            Section("Блок") {
                TextField("Название", text: $block.title)

                DatePicker(
                    "Начало",
                    selection: $block.plannedStart,
                    displayedComponents: [.hourAndMinute]
                )

                DatePicker(
                    "Окончание",
                    selection: $block.plannedEnd,
                    in: block.plannedStart...,
                    displayedComponents: [.hourAndMinute]
                )
            }

            Section("Длительность") {
                Text(durationText)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Редактирование")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") { dismiss() }
            }
        }
    }

    private var durationText: String {
        let minutes = max(0, Int(block.plannedDuration / 60))
        let hours = minutes / 60
        let remainder = minutes % 60

        if hours > 0 && remainder > 0 {
            return "\(hours) ч \(remainder) мин"
        } else if hours > 0 {
            return "\(hours) ч"
        } else {
            return "\(remainder) мин"
        }
    }
}
