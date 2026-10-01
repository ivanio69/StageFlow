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

struct RehearsalLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(
            for: RehearsalActivityAttributes.self
        ) { context in
            lockScreenView(context)
                .activityBackgroundTint(
                    .black.opacity(0.88)
                )
                .activitySystemActionForegroundColor(
                    .white
                )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text("Сейчас")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(context.state.blockTitle)
                            .font(.headline)
                            .lineLimit(2)
                            .invalidatableContent()
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(
                        alignment: .trailing,
                        spacing: 2
                    ) {
                        Text("Таймер")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        liveTimer(
                            context.state,
                            compact: false
                        )
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            nextBlockView(
                                context.state
                            )

                            Spacer(minLength: 8)

                            if !context.state.isFinished {
                                advanceButton(context)
                            }
                        }
                        .invalidatableContent()

                        HStack {
                            Text(
                                deltaText(
                                    context.state
                                        .scheduleDeltaSeconds
                                )
                            )
                            .foregroundStyle(
                                deltaColor(
                                    context.state
                                        .scheduleDeltaSeconds
                                )
                            )

                            Spacer()

                            if let finish = context.state
                                .predictedFinish,
                               !context.state.isFinished {
                                Text(
                                    "Финиш ~ \(finish.formatted(date: .omitted, time: .shortened))"
                                )
                                .monospacedDigit()
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(
                    systemName: context.state.isFinished
                        ? "checkmark.circle.fill"
                        : "play.fill"
                )
            } compactTrailing: {
                liveTimer(
                    context.state,
                    compact: true
                )
            } minimal: {
                Image(
                    systemName: context.state.isFinished
                        ? "checkmark"
                        : "play.fill"
                )
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(
        _ context: ActivityViewContext<
            RehearsalActivityAttributes
        >
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack(alignment: .top) {
                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(
                        context.attributes.rehearsalTitle
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                    Text(context.state.blockTitle)
                        .font(.headline)
                        .lineLimit(2)
                        .invalidatableContent()
                }

                Spacer(minLength: 12)

                Text(
                    deltaText(
                        context.state
                            .scheduleDeltaSeconds
                    )
                )
                .font(
                    .subheadline
                        .bold()
                        .monospacedDigit()
                )
                .foregroundStyle(
                    deltaColor(
                        context.state
                            .scheduleDeltaSeconds
                    )
                )
            }

            if context.state.isFinished {
                Label(
                    "На сегодня всё",
                    systemImage: "checkmark.seal.fill"
                )
                .font(.headline)
            } else {
                HStack(
                    alignment: .firstTextBaseline
                ) {
                    Label(
                        "Таймер",
                        systemImage: "stopwatch.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Spacer()

                    liveTimer(
                        context.state,
                        compact: false
                    )
                    .font(
                        .system(
                            size: 26,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                }

                HStack(spacing: 10) {
                    nextBlockView(
                        context.state
                    )
                    .invalidatableContent()

                    Spacer(minLength: 8)

                    advanceButton(context)
                }

                HStack {
                    if let end = context.state
                        .plannedEnd {
                        Text(
                            "План до \(end.formatted(date: .omitted, time: .shortened))"
                        )
                    }

                    Spacer()

                    if let predicted = context.state
                        .predictedFinish {
                        Text(
                            "Финиш ~ \(predicted.formatted(date: .omitted, time: .shortened))"
                        )
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
        }
        .padding()
    }

    @ViewBuilder
    private func liveTimer(
        _ state: RehearsalActivityAttributes
            .ContentState,
        compact: Bool
    ) -> some View {
        if state.isRunning,
           let actualStart = state.actualStart {
            let horizon = actualStart
                .addingTimeInterval(24 * 60 * 60)

            if compact {
                Text(
                    timerInterval:
                        actualStart...horizon,
                    countsDown: false,
                    showsHours: false
                )
                .font(
                    .caption2
                        .bold()
                        .monospacedDigit()
                )
                .frame(
                    width: 48,
                    alignment: .trailing
                )
            } else {
                Text(
                    timerInterval:
                        actualStart...horizon,
                    countsDown: false,
                    showsHours: true
                )
                .monospacedDigit()
            }
        } else if state.isFinished {
            Text("готово")
                .foregroundStyle(.green)
        } else {
            Text("готов")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func nextBlockView(
        _ state: RehearsalActivityAttributes
            .ContentState
    ) -> some View {
        if let next = state.nextBlockTitle {
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("Далее")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 5) {
                    Text(next)
                        .font(.caption.bold())
                        .lineLimit(1)

                    if let start = state.nextBlockStart {
                        Text(
                            "· \(start.formatted(date: .omitted, time: .shortened))"
                        )
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                }
            }
        } else if state.isRunning {
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("Далее")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("Завершение репетиции")
                    .font(.caption.bold())
                    .lineLimit(1)
            }
        } else {
            EmptyView()
        }
    }

    private func advanceButton(
        _ context: ActivityViewContext<
            RehearsalActivityAttributes
        >
    ) -> some View {
        Button(
            intent: AdvanceRehearsalIntent(
                rehearsalID: context
                    .attributes
                    .rehearsalID
                    .uuidString
            )
        ) {
            Label(
                "Дальше",
                systemImage: "forward.fill"
            )
            .font(.caption.bold())
        }
        .buttonStyle(.borderedProminent)
        .tint(.white.opacity(0.18))
    }

    private func deltaText(
        _ seconds: TimeInterval
    ) -> String {
        let minutes = Int(
            (abs(seconds) / 60).rounded()
        )

        guard minutes > 0 else {
            return "По графику"
        }

        return seconds > 0
            ? "+\(minutes) мин"
            : "−\(minutes) мин"
    }

    private func deltaColor(
        _ seconds: TimeInterval
    ) -> Color {
        if seconds > 30 {
            return .orange
        }

        if seconds < -30 {
            return .green
        }

        return .secondary
    }
}
