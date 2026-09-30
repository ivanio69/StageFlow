import SwiftUI

struct RehearsalRunView: View {
    @Environment(\.dismiss) private var dismiss
    let rehearsal: Rehearsal

    @State private var now = Date()
    @State private var noteText = ""

    private var running: RehearsalBlock? {
        ScheduleEngine.currentBlock(in: rehearsal)
    }

    private var next: RehearsalBlock? {
        ScheduleEngine.nextBlock(in: rehearsal)
    }

    private var delta: TimeInterval {
        ScheduleEngine.scheduleDelta(in: rehearsal, now: now)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("РЕПЕТИЦИЯ")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(rehearsal.title)
                                .font(.title2.bold())
                        }
                        Spacer()
                        TimeDeltaBadge(seconds: delta)
                    }

                    currentCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Прогноз окончания")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(ScheduleEngine.predictedFinish(in: rehearsal, now: now).formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                    }

                    quickNote

                    if let next, running != nil {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Далее")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(next.title)
                                .font(.headline)
                            Text(next.plannedStart.formatted(date: .omitted, time: .shortened))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            PhoneWatchSessionManager.shared.sync(rehearsal: rehearsal)
            await LiveActivityManager.shared.startOrUpdate(rehearsal: rehearsal, now: now)
            var ticks = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                now = Date()
                ticks += 1
                if ticks % 30 == 0 {
                    await LiveActivityManager.shared.startOrUpdate(rehearsal: rehearsal, now: now)
                }
            }
        }
    }

    @ViewBuilder
    private var currentCard: some View {
        if let running {
            VStack(alignment: .leading, spacing: 18) {
                Text(running.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("\(running.plannedStart.formatted(date: .omitted, time: .shortened))–\(running.plannedEnd.formatted(date: .omitted, time: .shortened))")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Button {
                    finish(running)
                } label: {
                    Label("Завершить блок", systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        } else if let next {
            VStack(alignment: .leading, spacing: 18) {
                Text(next.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Старт по плану в \(next.plannedStart.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)

                Button {
                    start(next)
                } label: {
                    Label("Начать блок", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        } else {
            ContentUnavailableView("На сегодня всё", systemImage: "checkmark.seal.fill")
        }
    }

    private var quickNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Быстрая заметка")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom) {
                TextField("Что нужно исправить?", text: $noteText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button("Добавить", systemImage: "plus") {
                    let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    rehearsal.notes.append(RehearsalNote(text: trimmed, blockID: running?.id))
                    noteText = ""
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func start(_ block: RehearsalBlock) {
        if rehearsal.actualStart == nil { rehearsal.actualStart = Date() }
        block.actualStart = Date()
        block.status = .running
        PhoneWatchSessionManager.shared.sync(rehearsal: rehearsal)
        Task { await LiveActivityManager.shared.startOrUpdate(rehearsal: rehearsal) }
    }

    private func finish(_ block: RehearsalBlock) {
        block.actualEnd = Date()
        block.status = .completed
        if ScheduleEngine.nextBlock(in: rehearsal) == nil {
            rehearsal.actualEnd = Date()
        }
        PhoneWatchSessionManager.shared.sync(rehearsal: rehearsal)
        if ScheduleEngine.nextBlock(in: rehearsal) == nil {
            Task { await LiveActivityManager.shared.end(rehearsal: rehearsal) }
        } else {
            Task { await LiveActivityManager.shared.startOrUpdate(rehearsal: rehearsal) }
        }
    }
}
