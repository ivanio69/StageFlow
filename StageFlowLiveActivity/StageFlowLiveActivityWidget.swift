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
                .activityBackgroundTint(.black.opacity(0.94))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(
                        alignment: .leading,
                        spacing: 3
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
                    .padding(.leading, 3)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(
                        alignment: .trailing,
                        spacing: 3
                    ) {
                        liveTimer(
                            context.state,
                            compact: false
                        )
                        .font(
                            .system(
                                size: 22,
                                weight: .semibold,
                                design: .rounded
                            )
                        )

                        deltaTextView(
                            context.state.scheduleDeltaSeconds,
                            compact: true
                        )
                    }
                    .padding(.trailing, 3)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 9) {
                        progressView(context.state)

                        HStack(
                            alignment: .center,
                            spacing: 10
                        ) {
                            nextCueCard(
                                context.state,
                                compact: true
                            )
                            .invalidatableContent()

                            if !context.state.isFinished {
                                advanceButton(
                                    context,
                                    compact: true
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 3)
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(
                    systemName: context.state.isFinished
                        ? "checkmark"
                        : "play.fill"
                )
                .font(.caption2.bold())
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
        if context.state.isFinished {
            finishedView(context)
        } else {
            VStack(
                alignment: .leading,
                spacing: 11
            ) {
                header(context)

                Text(context.state.blockTitle)
                    .font(.title3.weight(.semibold))
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
                            size: 32,
                            weight: .semibold,
                            design: .rounded
                        )
                    )

                    Spacer(minLength: 8)

                    if let end = context.state.plannedEnd {
                        VStack(
                            alignment: .trailing,
                            spacing: 1
                        ) {
                            Text("план")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)

                            Text(
                                end.formatted(
                                    date: .omitted,
                                    time: .shortened
                                )
                            )
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        }
                    }
                }

                progressView(context.state)

                HStack(
                    alignment: .center,
                    spacing: 10
                ) {
                    nextCueCard(
                        context.state,
                        compact: false
                    )
                    .invalidatableContent()

                    advanceButton(
                        context,
                        compact: false
                    )
                }

                footer(context.state)
            }
            .padding(.horizontal, 16)
            .padding(.top, 13)
            .padding(.bottom, 14)
        }
    }

    private func header(
        _ context: ActivityViewContext<
            RehearsalActivityAttributes
        >
    ) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 5, height: 5)

                Text(context.attributes.rehearsalTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            deltaTextView(
                context.state.scheduleDeltaSeconds,
                compact: false
            )
        }
    }

    private func finishedView(
        _ context: ActivityViewContext<
            RehearsalActivityAttributes
        >
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.14))
                    .frame(width: 38, height: 38)

                Image(systemName: "checkmark")
                    .font(.headline.bold())
                    .foregroundStyle(.green)
            }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(context.attributes.rehearsalTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("Репетиция завершена")
                    .font(.headline)

                if let finishedAt = context.state.predictedFinish {
                    Text(
                        finishedAt.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func progressView(
        _ state: RehearsalActivityAttributes
            .ContentState
    ) -> some View {
        if state.isRunning,
           let actualStart = state.actualStart,
           let plannedStart = state.plannedStart,
           let plannedEnd = state.plannedEnd {
            let duration = max(
                1,
                plannedEnd.timeIntervalSince(plannedStart)
            )
            let expectedEnd = actualStart
                .addingTimeInterval(duration)

            ProgressView(
                timerInterval: actualStart...expectedEnd,
                countsDown: false
            )
            .progressViewStyle(.linear)
            .tint(
                deltaColor(
                    state.scheduleDeltaSeconds
                )
            )
            .frame(height: 3)
        } else {
            Capsule()
                .fill(.white.opacity(0.1))
                .frame(height: 3)
        }
    }

    @ViewBuilder
    private func nextCueCard(
        _ state: RehearsalActivityAttributes
            .ContentState,
        compact: Bool
    ) -> some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: compact ? 7 : 9
                )
                .fill(.white.opacity(0.08))
                .frame(
                    width: compact ? 28 : 34,
                    height: compact ? 28 : 34
                )

                Image(
                    systemName: state.nextBlockTitle == nil
                        ? "checkered.flag"
                        : "forward.fill"
                )
                .font(
                    compact
                        ? .caption2.bold()
                        : .caption.bold()
                )
                .foregroundStyle(.secondary)
            }

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("Далее")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if let next = state.nextBlockTitle {
                    HStack(spacing: 5) {
                        Text(next)
                            .font(
                                compact
                                    ? .caption.weight(.semibold)
                                    : .subheadline.weight(.semibold)
                            )
                            .lineLimit(1)

                        if let start = state.nextBlockStart {
                            Text(
                                start.formatted(
                                    date: .omitted,
                                    time: .shortened
                                )
                            )
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("Завершение")
                        .font(
                            compact
                                ? .caption.weight(.semibold)
                                : .subheadline.weight(.semibold)
                        )
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 6 : 8)
        .background(
            .white.opacity(0.045),
            in: RoundedRectangle(
                cornerRadius: compact ? 12 : 14
            )
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private func footer(
        _ state: RehearsalActivityAttributes
            .ContentState
    ) -> some View {
        HStack(spacing: 6) {
            if let predicted = state.predictedFinish {
                Image(systemName: "flag")
                    .font(.caption2)

                Text(
                    "Финиш ~ \(predicted.formatted(date: .omitted, time: .shortened))"
                )
                .monospacedDigit()
            }

            Spacer()
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
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

            Text(
                timerInterval:
                    actualStart...horizon,
                countsDown: false,
                showsHours: !compact
            )
            .font(
                compact
                    ? .caption2.bold().monospacedDigit()
                    : .body.monospacedDigit()
            )
            .frame(
                width: compact ? 48 : nil,
                alignment: .trailing
            )
        } else {
            Text("готов")
                .foregroundStyle(.secondary)
        }
    }

    private func advanceButton(
        _ context: ActivityViewContext<
            RehearsalActivityAttributes
        >,
        compact: Bool
    ) -> some View {
        Button(
            intent: AdvanceRehearsalIntent(
                rehearsalID: context
                    .attributes
                    .rehearsalID
                    .uuidString
            )
        ) {
            if compact {
                Image(systemName: "arrow.right")
                    .font(.caption.bold())
                    .frame(
                        width: 30,
                        height: 30
                    )
            } else {
                HStack(spacing: 6) {
                    Text("Дальше")
                    Image(systemName: "arrow.right")
                }
                .font(.caption.bold())
                .padding(.horizontal, 3)
                .frame(height: 34)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.white.opacity(0.14))
    }

    private func deltaTextView(
        _ seconds: TimeInterval,
        compact: Bool
    ) -> some View {
        Text(deltaText(seconds))
            .font(
                compact
                    ? .caption2.bold().monospacedDigit()
                    : .caption.bold().monospacedDigit()
            )
            .foregroundStyle(deltaColor(seconds))
            .padding(.horizontal, compact ? 0 : 8)
            .padding(.vertical, compact ? 0 : 4)
            .background {
                if !compact {
                    Capsule()
                        .fill(
                            deltaColor(seconds)
                                .opacity(0.1)
                        )
                }
            }
    }

    private func deltaText(
        _ seconds: TimeInterval
    ) -> String {
        let minutes = Int(
            (abs(seconds) / 60).rounded()
        )

        guard minutes > 0 else {
            return "по графику"
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
