import SwiftUI

struct BlockEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let rehearsal: Rehearsal
    @Bindable var block: RehearsalBlock

    @State private var showingResetConfirmation = false

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

            Section("Статус") {
                LabeledContent(
                    "Сейчас",
                    value: block.status.title
                )

                if block.status == .planned {
                    Button(
                        "Отменить блок",
                        systemImage: "xmark.circle",
                        role: .destructive
                    ) {
                        block.status = .cancelled
                    }
                } else {
                    Button(
                        "Вернуть в план",
                        systemImage: "arrow.uturn.backward"
                    ) {
                        showingResetConfirmation = true
                    }
                }
            }
        }
        .navigationTitle("Редактирование")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .confirmationAction
            ) {
                Button("Готово") {
                    dismiss()
                }
            }
        }
        .alert(
            "Вернуть блок в план?",
            isPresented: $showingResetConfirmation
        ) {
            Button("Вернуть") {
                resetBlock()
            }

            Button(
                "Отмена",
                role: .cancel
            ) {}
        } message: {
            Text(
                "Фактическое время старта и окончания этого блока будет удалено."
            )
        }
    }

    private var durationText: String {
        let minutes = max(
            0,
            Int(block.plannedDuration / 60)
        )

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

    private func resetBlock() {
        block.status = .planned
        block.actualStart = nil
        block.actualEnd = nil

        if rehearsal.actualEnd != nil {
            rehearsal.actualEnd = nil
        }
    }
}
