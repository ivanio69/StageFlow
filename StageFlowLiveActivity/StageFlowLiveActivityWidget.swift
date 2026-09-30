import ActivityKit
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
        ActivityConfiguration(for: RehearsalActivityAttributes.self) { context in
            lockScreenView(context)
                .activityBackgroundTint(.black.opacity(0.88))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Сейчас")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.blockTitle)
                            .font(.headline)
                            .lineLimit(2)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(deltaText(context.state.scheduleDeltaSeconds))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(deltaColor(context.state.scheduleDeltaSeconds))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let next = context.state.nextBlockTitle {
                            Label(next, systemImage: "forward.fill")
                                .lineLimit(1)
                        } else if context.state.isFinished {
                            Label("На сегодня всё", systemImage: "checkmark.circle.fill")
                        }
                        Spacer()
                        if let finish = context.state.predictedFinish {
                            Text("до \(finish.formatted(date: .omitted, time: .shortened))")
                                .monospacedDigit()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: context.state.isFinished ? "checkmark.circle.fill" : "theatermasks.fill")
            } compactTrailing: {
                Text(compactDelta(context.state.scheduleDeltaSeconds))
                    .font(.caption2.bold().monospacedDigit())
                    .foregroundStyle(deltaColor(context.state.scheduleDeltaSeconds))
            } minimal: {
                Image(systemName: context.state.isFinished ? "checkmark" : "play.fill")
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(_ context: ActivityViewContext<RehearsalActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.rehearsalTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(context.state.blockTitle)
                        .font(.headline)
                        .lineLimit(2)
                }
                Spacer(minLength: 12)
                Text(deltaText(context.state.scheduleDeltaSeconds))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(deltaColor(context.state.scheduleDeltaSeconds))
            }

            HStack {
                if context.state.isFinished {
                    Label("На сегодня всё", systemImage: "checkmark.seal.fill")
                } else if let end = context.state.plannedEnd {
                    Label("План до \(end.formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                }

                Spacer()

                if let predicted = context.state.predictedFinish, !context.state.isFinished {
                    Text("Финиш ~ \(predicted.formatted(date: .omitted, time: .shortened))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func deltaText(_ seconds: TimeInterval) -> String {
        let minutes = Int((abs(seconds) / 60).rounded())
        guard minutes > 0 else { return "По графику" }
        return seconds > 0 ? "+\(minutes) мин" : "−\(minutes) мин"
    }

    private func compactDelta(_ seconds: TimeInterval) -> String {
        let minutes = Int((abs(seconds) / 60).rounded())
        guard minutes > 0 else { return "0" }
        return seconds > 0 ? "+\(minutes)" : "−\(minutes)"
    }

    private func deltaColor(_ seconds: TimeInterval) -> Color {
        if seconds > 30 { return .orange }
        if seconds < -30 { return .green }
        return .secondary
    }
}
