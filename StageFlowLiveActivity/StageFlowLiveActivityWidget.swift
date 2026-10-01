import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct StageFlowLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        RehearsalLiveActivityWidget()
    }
}

// Explicit foregrounds keep the dark stage card legible with either system appearance.
private enum CueStyle {
    static let background = Color(red: 0.055, green: 0.065, blue: 0.08)
    static let accent = Color(red: 0.70, green: 0.94, blue: 0.62)
    static let secondary = Color.white.opacity(0.66)
    static let muted = Color.white.opacity(0.48)
}

struct RehearsalLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RehearsalActivityAttributes.self) { context in
            RehearsalCueCard(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(CueStyle.background)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.phase, systemImage: context.state.symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CueStyle.accent)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    CueClock(state: context.state, size: 23, compact: true)
                        .foregroundStyle(.white)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(context.state.isFinished ? "Репетиция завершена" : context.state.blockTitle)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .invalidatableContent()
                        if !context.state.isFinished {
                            CueProgress(state: context.state)
                            CueNextRow(attributes: context.attributes, state: context.state, compact: true)
                        } else {
                            Text(context.attributes.rehearsalTitle)
                                .font(.caption)
                                .foregroundStyle(CueStyle.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 3)
                }
            } compactLeading: {
                Image(systemName: context.state.symbol)
                    .font(.caption2.bold())
                    .foregroundStyle(CueStyle.accent)
                    .accessibilityLabel(context.state.phase)
            } compactTrailing: {
                CueClock(state: context.state, size: 12, compact: true)
                    .foregroundStyle(CueStyle.accent)
            } minimal: {
                Image(systemName: context.state.symbol)
                    .foregroundStyle(CueStyle.accent)
                    .accessibilityLabel(context.state.phase)
            }
            .keylineTint(CueStyle.accent)
        }
    }
}

private struct RehearsalCueCard: View {
    let attributes: RehearsalActivityAttributes
    let state: RehearsalActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isFinished {
                finished
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.path")
                            .foregroundStyle(CueStyle.accent)
                        Text(attributes.rehearsalTitle)
                            .foregroundStyle(CueStyle.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        drift
                            .fixedSize()
                    }
                    .font(.caption2.weight(.medium))

                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(state.phase.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(CueStyle.accent)
                            Text(state.blockTitle)
                                .font(.system(size: 16, weight: .semibold))
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .invalidatableContent()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .trailing, spacing: 4) {
                            CueClock(state: state, size: 30, compact: false)
                            if let end = state.plannedEnd {
                                Text("до \(end.formatted(date: .omitted, time: .shortened)) по плану")
                                    .font(.system(size: 10))
                                    .foregroundStyle(CueStyle.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                    CueProgress(state: state)
                    CueNextRow(attributes: attributes, state: state, compact: false)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(alignment: .topLeading) {
            LinearGradient(
                colors: [CueStyle.accent.opacity(0.075), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var drift: some View {
        let minutes = Int((abs(state.scheduleDeltaSeconds) / 60).rounded())
        let late = state.scheduleDeltaSeconds > 0
        let color = minutes == 0 ? CueStyle.secondary : (late ? Color.orange : CueStyle.accent)
        return HStack(spacing: 4) {
            Image(systemName: minutes == 0 ? "checkmark" : (late ? "arrow.up.right" : "arrow.down.right"))
            Text(minutes == 0 ? "По графику" : "\(late ? "+" : "−")\(minutes) мин")
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(minutes == 0 ? "По графику" : "\(late ? "Отставание" : "Опережение") на \(minutes) минут")
    }

    private var finished: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(CueStyle.accent)
                .frame(width: 44, height: 44)
                .background(CueStyle.accent.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(attributes.rehearsalTitle)
                    .font(.caption)
                    .foregroundStyle(CueStyle.secondary)
                    .lineLimit(1)
                Text("Репетиция завершена")
                    .font(.headline)
                if let end = state.predictedFinish {
                    Text("Финиш в \(end.formatted(date: .omitted, time: .shortened))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(CueStyle.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private struct CueClock: View {
    let state: RehearsalActivityAttributes.ContentState
    let size: CGFloat
    let compact: Bool

    var body: some View {
        Group {
            if state.isFinished {
                Image(systemName: "checkmark")
            } else if state.isRunning, let start = state.actualStart {
                // System-rendered text keeps ticking while the app is suspended.
                Text(timerInterval: start...start.addingTimeInterval(24 * 60 * 60),
                     countsDown: false, showsHours: true)
                    .multilineTextAlignment(.trailing)
                    .frame(width: compact ? 64 : 126, alignment: .trailing)
                    .accessibilityLabel("Прошло времени")
            } else {
                Text(compact ? "Старт" : "—:—")
            }
        }
        .font(.system(size: size, weight: .medium, design: .rounded).monospacedDigit())
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}

private struct CueProgress: View {
    let state: RehearsalActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isRunning,
               let actual = state.actualStart,
               let start = state.plannedStart,
               let end = state.plannedEnd {
                ProgressView(timerInterval: actual...actual.addingTimeInterval(max(1, end.timeIntervalSince(start))), countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.linear)
                .tint(CueStyle.accent)
                .accessibilityLabel("Прогресс текущего блока")
            } else {
                Capsule().fill(.white.opacity(0.12))
            }
        }
        .frame(height: 3)
        .clipShape(Capsule())
    }
}

private struct CueNextRow: View {
    let attributes: RehearsalActivityAttributes
    let state: RehearsalActivityAttributes.ContentState
    let compact: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(state.nextBlockTitle == nil ? "ФИНИШ" : "ДАЛЕЕ")
                        .tracking(1)
                    if let start = state.nextBlockStart, state.nextBlockTitle != nil {
                        Text("· \(start.formatted(date: .omitted, time: .shortened))")
                            .monospacedDigit()
                    } else if let finish = state.predictedFinish {
                        Text("≈ \(finish.formatted(date: .omitted, time: .shortened))")
                            .monospacedDigit()
                    }
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(CueStyle.muted)
                .lineLimit(1)
                Text(state.nextBlockTitle ?? "Последний блок")
                    .font(.system(size: compact ? 12 : 13, weight: .medium))
                    .foregroundStyle(CueStyle.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .invalidatableContent()

            Button(intent: AdvanceRehearsalIntent(rehearsalID: attributes.rehearsalID.uuidString)) {
                HStack(spacing: 6) {
                    if !compact {
                        Text(state.actionTitle)
                    }
                    Image(systemName: state.actionSymbol)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(CueStyle.background)
                .padding(.horizontal, compact ? 0 : 14)
                .frame(minWidth: 44, minHeight: 44)
                .background(CueStyle.accent, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .fixedSize()
            .accessibilityLabel(state.actionTitle)
            .accessibilityHint(state.isRunning ? "Завершить текущий блок\(state.nextBlockTitle == nil ? " и репетицию" : " и начать следующий")" : "Запустить текущий блок")
        }
    }
}

private extension RehearsalActivityAttributes.ContentState {
    var phase: String { isFinished ? "Завершено" : (isRunning ? "Сейчас" : "Готовы к старту") }
    var symbol: String { isFinished ? "checkmark" : (isRunning ? "waveform" : "play.fill") }
    var actionTitle: String { !isRunning ? "Начать" : (nextBlockTitle == nil ? "Завершить" : "Дальше") }
    var actionSymbol: String { !isRunning ? "play.fill" : (nextBlockTitle == nil ? "checkmark" : "arrow.right") }
}

#if DEBUG
private enum CuePreview {
    static let attributes = RehearsalActivityAttributes(rehearsalID: UUID(), rehearsalTitle: "Большая сцена · Прогон")

    static func state(running: Bool = true, finished: Bool = false, last: Bool = false, longTitle: Bool = false) -> RehearsalActivityAttributes.ContentState {
        let now = Date()
        return .init(
            blockTitle: longTitle ? "Финальная сцена с полным составом и оркестром" : "Свет и пластика",
            plannedStart: now.addingTimeInterval(-300),
            plannedEnd: now.addingTimeInterval(600),
            actualStart: running && !finished ? now.addingTimeInterval(-240) : nil,
            scheduleDeltaSeconds: longTitle ? 420 : 0,
            predictedFinish: finished ? now : now.addingTimeInterval(1800),
            nextBlockTitle: last || finished ? nil : "Финальный выход",
            nextBlockStart: last || finished ? nil : now.addingTimeInterval(660),
            isRunning: running && !finished,
            isFinished: finished
        )
    }
}

#Preview("Экран блокировки", as: .content, using: CuePreview.attributes) {
    RehearsalLiveActivityWidget()
} contentStates: {
    CuePreview.state()
    CuePreview.state(running: false)
    CuePreview.state(last: true)
    CuePreview.state(longTitle: true)
    CuePreview.state(finished: true)
}

#Preview("Остров · развёрнутый", as: .dynamicIsland(.expanded), using: CuePreview.attributes) {
    RehearsalLiveActivityWidget()
} contentStates: {
    CuePreview.state()
    CuePreview.state(longTitle: true)
    CuePreview.state(finished: true)
}

#Preview("Остров · компактный", as: .dynamicIsland(.compact), using: CuePreview.attributes) {
    RehearsalLiveActivityWidget()
} contentStates: {
    CuePreview.state()
    CuePreview.state(running: false)
    CuePreview.state(finished: true)
}
#endif
