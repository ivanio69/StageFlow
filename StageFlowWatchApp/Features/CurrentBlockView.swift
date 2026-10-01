import SwiftUI

private enum WatchCueStyle {
    static let background = Color(red: 0.055, green: 0.065, blue: 0.08)
    static let accent = Color(red: 0.70, green: 0.94, blue: 0.62)
    static let secondary = Color.white.opacity(0.66)
}

struct CurrentBlockView: View {
    let session: WatchSessionManager
    @State private var showingNote = false
    @State private var noteText = ""

    private var snapshot: WatchSnapshot { session.snapshot }
    private var isActive: Bool { snapshot.mode == .ready || snapshot.mode == .running }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Label(snapshot.rehearsalTitle, systemImage: "waveform.path")
                    .font(.caption2)
                    .foregroundStyle(WatchCueStyle.secondary)
                    .lineLimit(2)
                if isActive {
                    cue
                    primaryAction
                    nextCue
                    secondaryActions
                } else {
                    restingState
                }
                if !session.isPhoneReachable {
                    Label("Нет связи с iPhone", systemImage: "iphone.slash")
                        .font(.caption2)
                        .foregroundStyle(WatchCueStyle.secondary)
                }
                if let status = session.statusMessage {
                    Text(status)
                        .font(.caption2)
                        .foregroundStyle(WatchCueStyle.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .foregroundStyle(.white)
        .background(WatchCueStyle.background.ignoresSafeArea())
        .tint(WatchCueStyle.accent)
        .sheet(isPresented: $showingNote) { noteComposer }
    }

    private var cue: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(snapshot.mode == .running ? "СЕЙЧАС" : "ГОТОВЫ К СТАРТУ")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(WatchCueStyle.accent)
            Text(snapshot.blockTitle)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Group {
                if snapshot.mode == .running, let start = snapshot.actualStart {
                    Text(timerInterval: start...start.addingTimeInterval(24 * 60 * 60),
                         countsDown: false, showsHours: true)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("—:—")
                        .foregroundStyle(WatchCueStyle.secondary)
                        .accessibilityLabel("Блок ещё не начат")
                }
            }
            .font(.system(size: 38, weight: .medium, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    drift
                    Spacer(minLength: 0)
                    plannedEnd
                }
                VStack(alignment: .leading, spacing: 4) {
                    drift
                    plannedEnd
                }
            }
            .font(.caption2)

            if snapshot.mode == .running {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    ProgressView(value: progress(at: context.date))
                        .tint(WatchCueStyle.accent)
                        .accessibilityLabel("Прогресс текущего блока")
                }
            } else {
                Capsule().fill(.white.opacity(0.12))
                    .frame(height: 3)
                    .accessibilityHidden(true)
            }
        }
    }

    private var drift: some View {
        let minutes = Int((abs(snapshot.scheduleDeltaSeconds) / 60).rounded())
        let late = snapshot.scheduleDeltaSeconds > 0
        return Label {
            Text(minutes == 0 ? "По графику" : "\(late ? "+" : "−")\(minutes) мин")
                .monospacedDigit()
        } icon: {
            Image(systemName: minutes == 0 ? "checkmark" : (late ? "arrow.up.right" : "arrow.down.right"))
        }
        .foregroundStyle(minutes == 0 ? WatchCueStyle.secondary : (late ? .orange : WatchCueStyle.accent))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(minutes == 0 ? "По графику" : "\(late ? "Отставание" : "Опережение") на \(minutes) минут")
    }

    @ViewBuilder private var plannedEnd: some View {
        if let end = snapshot.plannedEnd {
            Text("до \(end.formatted(date: .omitted, time: .shortened))")
                .monospacedDigit()
                .foregroundStyle(WatchCueStyle.secondary)
                .accessibilityLabel("По плану до \(end.formatted(date: .omitted, time: .shortened))")
        }
    }

    private var primaryAction: some View {
        Button {
            if snapshot.mode == .running {
                session.finishCurrentBlock()
            } else {
                session.startNextBlock()
            }
        } label: {
            Label(snapshot.mode == .running ? "Завершить" : "Начать",
                  systemImage: snapshot.mode == .running ? "checkmark" : "play.fill")
                .font(.body.bold())
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(WatchCueStyle.background)
                .background(WatchCueStyle.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!session.isPhoneReachable)
        .opacity(session.isPhoneReachable ? 1 : 0.4)
        .accessibilityHint(snapshot.mode == .running ? "Завершить текущий блок" : "Начать текущий блок")
    }

    private var nextCue: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let next = snapshot.nextBlockTitle {
                Text("ДАЛЕЕ")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(WatchCueStyle.secondary)
                Text(next)
                    .font(.footnote.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            } else if snapshot.mode == .running {
                Label("Последний блок", systemImage: "flag.checkered")
                    .font(.footnote)
            }
            if let finish = snapshot.predictedFinish {
                Text("Финиш ≈ \(finish.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(WatchCueStyle.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var secondaryActions: some View {
        VStack(spacing: 6) {
            Button { showingNote = true } label: {
                Label("Заметка", systemImage: "square.and.pencil")
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            if snapshot.mode == .ready {
                Button(role: .destructive) { session.skipNextBlock() } label: {
                    Label("Пропустить", systemImage: "forward.end")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .disabled(!session.isPhoneReachable)
            }
        }
        .font(.footnote)
        .buttonStyle(.bordered)
        .tint(.white.opacity(0.1))
    }

    private var restingState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: snapshot.mode == .finished ? "checkmark" : "iphone")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(WatchCueStyle.accent)
                .frame(width: 48, height: 48)
                .background(WatchCueStyle.accent.opacity(0.12), in: Circle())
            Text(snapshot.mode == .finished ? "Репетиция завершена" : snapshot.blockTitle)
                .font(.headline)
            Text(snapshot.mode == .finished ? "На сегодня всё" : "Выберите график на iPhone — он появится здесь.")
                .font(.footnote)
                .foregroundStyle(WatchCueStyle.secondary)
        }
        .padding(.vertical, 8)
    }

    private var noteComposer: some View {
        NavigationStack {
            ScrollView {
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
                            .foregroundStyle(WatchCueStyle.background)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WatchCueStyle.accent)
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Отмена") { showingNote = false }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Заметка")
        }
    }

    private func progress(at date: Date) -> Double {
        guard let actualStart = snapshot.actualStart,
              let plannedStart = snapshot.plannedStart,
              let plannedEnd = snapshot.plannedEnd else { return 0 }
        let duration = plannedEnd.timeIntervalSince(plannedStart)
        guard duration > 0 else { return 0 }
        return min(max(date.timeIntervalSince(actualStart) / duration, 0), 1)
    }
}
