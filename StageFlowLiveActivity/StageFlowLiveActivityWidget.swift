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
                .activityBackgroundTint(.black.opacity(0.92))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        Text(context.attributes.rehearsalTitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(context.state.blockTitle)
                            .font(.headline)
                            .lineLimit(2)
                            .invalidatableContent()
                    }
                    .padding(.leading, 2)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(
                        alignment: .trailing,
                        spacing: 4
                    ) {
                        liveTimer(
                            context.state,
                            compact: false
                        )
                        .font(
                            .system(
                                size: 22,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                        Text(
                            deltaText(
                                context.state
                                    .scheduleDeltaSeconds
                            )
                        )
                        .font(.caption2.bold())
                        .foregroundStyle(
                            deltaColor(
                                context.state
                                    .scheduleDeltaSeconds
                            )
                        )
                    }
                    .padding(.trailing, 2)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        Divider()
                            .opacity(0.22)

                        HStack(
                            alignment: .center,
                            spacing: 10
                        ) {
                            nextBlockView(
                                context.state
                            )
                            .invalidatableContent()

                            Spacer(minLength: 6)

                            if !context.state.isFinished {
                                advanceButton(context)
                            }
                        }

                        HStack(spacing: 8) {
                            if let end = context.state
                                .plannedEnd,
                               !context.state.isFinished {
                                Label(
                                    end.formatted(
                                        date: .omitted,
                                        time: .shortened
                                    ),
                                    systemImage: "clock"
                                )
                            }

                            Spacer()

                            if let finish = context.state
                                .predictedFinish,
                               !context.state.isFinished {
                                Text(
                                    "Финиш ~ \(finish.formatted(date: .omitted, time: .shortened))"
                                )
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 2)
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
            HStack(
                alignment: .center,
                spacing: 10
            ) {
                Text(context.attributes.rehearsalTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                deltaBadge(
                    context.state.scheduleDeltaSeconds
                )
            }

            if context.state.isFinished {
                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    Label(
                        "На сегодня всё",
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.headline)

                    if let finishedAt = context.state.predictedFinish {
                        Text(
                            "Завершено в \(finishedAt.formatted(date: .omitted, time: .shortened))"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    }
                }
            } else {
                Text(context.state.blockTitle)
                    .font(.title3.bold())
                    .lineLimit(2)
                    .invalidatableContent()

                HStack(
                    alignment: .firstTextBaseline,
                    spacing: 10
                ) {
                    liveTimer(
                        context.state,
                        compact: false
                    )
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                    Spacer(minLength: 8)

                    if let end = context.state.plannedEnd {
                        VStack(
                            alignment: .trailing,
                            spacing: 2
                        ) {
                            Text("до")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(
                                end.formatted(
                                    date: .omitted,
                                    time: .shortened
                                )
                            )
                            .font(.subheadline.bold())
                            .monospacedDigit()
                        }
                    }
                }

                Divider()
                    .opacity(0.24)

                HStack(
                    alignment: .center,
                    spacing: 10
                ) {
                    nextBlockView(
                        context.state
                    )
                    .invalidatableContent()

                    Spacer(minLength: 6)

                    advanceButton(context)
                }

                if let predicted = context.state.predictedFinish {
                    HStack(spacing: 5) {
                        Image(systemName: "flag.checkered")
                        Text(
                            "Финиш ~ \(predicted.formatted(date: .omitted, time: .shortened))"
                        )
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
                spacing: 3
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
                spacing: 3
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
            HStack(spacing: 5) {
                Text("Дальше")
                Image(systemName: "forward.fill")
            }
            .font(.caption.bold())
            .padding(.horizontal, 2)
        }
        .buttonStyle(.borderedProminent)
        .tint(.white.opacity(0.16))
    }

    private func deltaBadge(
        _ seconds: TimeInterval
    ) -> some View {
        Text(deltaText(seconds))
            .font(.caption.bold().monospacedDigit())
            .foregroundStyle(deltaColor(seconds))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                deltaColor(seconds).opacity(0.12),
                in: Capsule()
            )
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
