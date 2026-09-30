import SwiftUI
import SwiftData

struct RehearsalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let rehearsal: Rehearsal

    @State private var blockTitle = ""
    @State private var blockStart = Date()
    @State private var blockEnd = Date().addingTimeInterval(30 * 60)

    var body: some View {
        NavigationStack {
            Form {
                Section("Добавить блок") {
                    TextField("Название", text: $blockTitle)

                    DatePicker(
                        "Начало",
                        selection: $blockStart,
                        displayedComponents: [.hourAndMinute]
                    )

                    DatePicker(
                        "Окончание",
                        selection: $blockEnd,
                        in: blockStart...,
                        displayedComponents: [.hourAndMinute]
                    )

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
                            NavigationLink {
                                BlockEditorView(block: block)
                            } label: {
                                BlockRow(block: block)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    duplicate(block)
                                } label: {
                                    Label("Дублировать", systemImage: "plus.square.on.square")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(block)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                        .onMove(perform: moveBlocks)
                    }
                }
            }
            .navigationTitle("График")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .onAppear(perform: prepareNewBlockTimes)
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

        modelContext.insert(block)
        rehearsal.blocks.append(block)

        blockTitle = ""
        blockStart = blockEnd
        blockEnd = blockEnd.addingTimeInterval(30 * 60)
    }

    private func duplicate(_ block: RehearsalBlock) {
        let copy = RehearsalBlock(
            title: block.title,
            plannedStart: block.plannedStart,
            plannedEnd: block.plannedEnd,
            orderIndex: block.orderIndex + 1
        )

        modelContext.insert(copy)
        rehearsal.blocks.append(copy)

        var blocks = rehearsal.sortedBlocks
        blocks.removeAll(where: { $0.id == copy.id })

        if let sourceIndex = blocks.firstIndex(where: { $0.id == block.id }) {
            blocks.insert(copy, at: min(sourceIndex + 1, blocks.count))
        } else {
            blocks.append(copy)
        }

        applyOrder(blocks)
    }

    private func delete(_ block: RehearsalBlock) {
        rehearsal.blocks.removeAll(where: { $0.id == block.id })
        modelContext.delete(block)
        normalizeOrder()
    }

    private func moveBlocks(from source: IndexSet, to destination: Int) {
        var blocks = rehearsal.sortedBlocks
        blocks.move(fromOffsets: source, toOffset: destination)
        applyOrder(blocks)
    }

    private func normalizeOrder() {
        applyOrder(rehearsal.sortedBlocks)
    }

    private func applyOrder(_ blocks: [RehearsalBlock]) {
        for (index, block) in blocks.enumerated() {
            block.orderIndex = index
        }
    }

    private func prepareNewBlockTimes() {
        if let last = rehearsal.sortedBlocks.last {
            blockStart = last.plannedEnd
            blockEnd = last.plannedEnd.addingTimeInterval(30 * 60)
        } else {
            blockStart = rehearsal.scheduledStart
            blockEnd = min(
                rehearsal.scheduledEnd,
                rehearsal.scheduledStart.addingTimeInterval(30 * 60)
            )
        }
    }
}
