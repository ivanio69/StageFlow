import SwiftUI

struct RehearsalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let rehearsal: Rehearsal

    @State private var blockTitle = ""
    @State private var blockStart = Date()
    @State private var blockEnd = Date().addingTimeInterval(30 * 60)

    var body: some View {
        NavigationStack {
            Form {
                Section("Добавить блок") {
                    TextField("Название", text: $blockTitle)
                    DatePicker("Начало", selection: $blockStart, displayedComponents: [.hourAndMinute])
                    DatePicker("Окончание", selection: $blockEnd, in: blockStart..., displayedComponents: [.hourAndMinute])
                    Button("Добавить в график", systemImage: "plus") {
                        addBlock()
                    }
                    .disabled(blockTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Блоки") {
                    if rehearsal.sortedBlocks.isEmpty {
                        Text("Пока пусто")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(rehearsal.sortedBlocks) { block in
                            BlockRow(block: block)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        rehearsal.blocks.removeAll(where: { $0.id == block.id })
                                        normalizeOrder()
                                    } label: {
                                        Label("Удалить", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("График")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .onAppear {
                if let last = rehearsal.sortedBlocks.last {
                    blockStart = last.plannedEnd
                    blockEnd = last.plannedEnd.addingTimeInterval(30 * 60)
                } else {
                    blockStart = rehearsal.scheduledStart
                    blockEnd = min(rehearsal.scheduledEnd, rehearsal.scheduledStart.addingTimeInterval(30 * 60))
                }
            }
        }
    }

    private func addBlock() {
        let title = blockTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let block = RehearsalBlock(
            title: title,
            plannedStart: blockStart,
            plannedEnd: blockEnd,
            orderIndex: rehearsal.blocks.count
        )
        rehearsal.blocks.append(block)
        blockTitle = ""
        blockStart = blockEnd
        blockEnd = blockEnd.addingTimeInterval(30 * 60)
    }

    private func normalizeOrder() {
        for (index, block) in rehearsal.sortedBlocks.enumerated() {
            block.orderIndex = index
        }
    }
}
