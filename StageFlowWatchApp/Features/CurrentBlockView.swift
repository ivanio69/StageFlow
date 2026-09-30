import SwiftUI

struct CurrentBlockView: View {
    let session: WatchSessionManager

    @State private var showingNote = false
    @State private var noteText = ""

    private var snapshot: WatchSnapshot {
        session.snapshot
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                header

                Text(snapshot.blockTitle)
                    .font(.title3.bold())
                    .lineLimit(3)

                HStack(alignment: .firstTextBaseline) {
                    Text(deltaText)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(deltaColor)

                    Spacer()

                    if let plannedEnd = snapshot.plannedEnd {
                        Text(plannedEnd.formatted(date: .omitted, time: .shortened))
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                if snapshot.mode == .running {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        VStack(alignment: .leading, spacing: 5) {
                            ProgressView(value: progress(at: context.date))
                            Text(remainingText(at: context.date))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let next = snapshot.nextBlockTitle {
                    Divider()
                    Text("Далее")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(next)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(2)
                }

                primaryAction

                if snapshot.mode == .ready || snapshot.mode == .running {
                    Button {
                        showingNote = true
                    } label: {
                        Label("Заметка", systemImage: "mic.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if let status = session.statusMessage {
                    Text(status)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .sheet(isPresented: $showingNote) {
            noteComposer
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(snapshot.rehearsalTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Circle()
                .fill(session.isPhoneReachable ? Color.green : Color.secondary)
                .frame(width: 6, height: 6)
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch snapshot.mode {
        case .running:
            Button {
                session.finishCurrentBlock()
            } label: {
                Label("Завершить", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!session.isPhoneReachable)

        case .ready:
            Button {
                session.startNextBlock()
            } label: {
                Label("Начать", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!session.isPhoneReachable)

        case .finished:
            Label("На сегодня всё", systemImage: "checkmark.seal.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)

        case .idle:
            Text("Нет активного графика")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }

    private var noteComposer: some View {
        NavigationStack {
            VStack(spacing: 10) {
                TextField("Заметка", text: $noteText)
                    .textInputAutocapitalization(.sentences)

                Button {
                    session.addNote(noteText)
                    noteText = ""
                    showingNote = false
                } label: {
                    Label("Сохранить", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Отмена") {
                    showingNote = false
                }
            }
            .padding(.horizontal, 4)
            .navigationTitle("Заметка")
        }
    }

    private var deltaText: String {
        let minutes = Int((abs(snapshot.scheduleDeltaSeconds) / 60).rounded())
        guard minutes > 0 else { return "По графику" }
        return snapshot.scheduleDeltaSeconds > 0 ? "+\(minutes) мин" : "−\(minutes) мин"
    }

    private var deltaColor: Color {
        if snapshot.scheduleDeltaSeconds > 30 { return .orange }
        if snapshot.scheduleDeltaSeconds < -30 { return .green }
        return .secondary
    }

    private func progress(at date: Date) -> Double {
        guard let actualStart = snapshot.actualStart,
              let plannedStart = snapshot.plannedStart,
              let plannedEnd = snapshot.plannedEnd else {
            return 0
        }

        let duration = plannedEnd.timeIntervalSince(plannedStart)
        guard duration > 0 else { return 0 }

        let elapsed = date.timeIntervalSince(actualStart)
        return min(max(elapsed / duration, 0), 1)
    }

    private func remainingText(at date: Date) -> String {
        guard let actualStart = snapshot.actualStart,
              let plannedStart = snapshot.plannedStart,
              let plannedEnd = snapshot.plannedEnd else {
            return ""
        }

        let duration = plannedEnd.timeIntervalSince(plannedStart)
        let expectedEnd = actualStart.addingTimeInterval(duration)
        let remaining = expectedEnd.timeIntervalSince(date)

        if remaining <= 0 {
            let minutes = max(1, Int((abs(remaining) / 60).rounded()))
            return "+\(minutes) мин сверх длительности"
        }

        let minutes = Int(remaining / 60)
        let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d осталось", minutes, seconds)
    }
}
