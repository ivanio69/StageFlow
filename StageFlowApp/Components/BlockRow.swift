import SwiftUI

struct BlockRow: View {
    let block: RehearsalBlock
    var rehearsal: Rehearsal? = nil

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(.headline)

                Text(plannedTime)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let timingDetail {
                    Text(timingDetail)
                        .font(.caption)
                        .foregroundStyle(timingDetailColor)
                }
            }

            Spacer()

            Image(systemName: icon)
                .foregroundStyle(iconStyle)
        }
        .padding(.vertical, 4)
    }

    private var plannedTime: String {
        "\(block.plannedStart.formatted(date: .omitted, time: .shortened))–\(block.plannedEnd.formatted(date: .omitted, time: .shortened))"
    }

    private var timingDetail: String? {
        switch block.status {
        case .completed:
            guard let actualStart = block.actualStart,
                  let actualEnd = block.actualEnd else {
                return "Завершено"
            }

            let delta = actualEnd.timeIntervalSince(block.plannedEnd)
            return "Факт \(actualStart.formatted(date: .omitted, time: .shortened))–\(actualEnd.formatted(date: .omitted, time: .shortened)) · \(ScheduleEngine.formattedDelta(delta))"

        case .running:
            guard let actualStart = block.actualStart,
                  let rehearsal else {
                return "Идёт"
            }

            let projectedEnd = ScheduleEngine.projectedEnd(for: block, in: rehearsal)
            return "Старт \(actualStart.formatted(date: .omitted, time: .shortened)) · финиш ~\(projectedEnd.formatted(date: .omitted, time: .shortened))"

        case .planned:
            guard let rehearsal else { return nil }

            let delta = ScheduleEngine.scheduleDelta(in: rehearsal)
            guard abs(delta) >= 30 else { return nil }

            let start = ScheduleEngine.projectedStart(for: block, in: rehearsal)
            let end = ScheduleEngine.projectedEnd(for: block, in: rehearsal)
            return "Прогноз \(start.formatted(date: .omitted, time: .shortened))–\(end.formatted(date: .omitted, time: .shortened))"

        case .skipped:
            return "Пропущено"

        case .cancelled:
            return "Отменено"
        }
    }

    private var timingDetailColor: Color {
        switch block.status {
        case .completed:
            guard let actualEnd = block.actualEnd else { return .secondary }
            let delta = actualEnd.timeIntervalSince(block.plannedEnd)
            if delta > 30 { return .orange }
            if delta < -30 { return .green }
            return .secondary

        case .running, .planned:
            guard let rehearsal else { return .secondary }
            let delta = ScheduleEngine.scheduleDelta(in: rehearsal)
            if delta > 30 { return .orange }
            if delta < -30 { return .green }
            return .secondary

        case .skipped, .cancelled:
            return .secondary
        }
    }

    private var icon: String {
        switch block.status {
        case .planned: "circle"
        case .running: "play.circle.fill"
        case .completed: "checkmark.circle.fill"
        case .skipped: "forward.end.circle"
        case .cancelled: "xmark.circle"
        }
    }

    private var iconStyle: Color {
        switch block.status {
        case .running: .orange
        case .completed: .green
        case .cancelled, .skipped: .secondary
        case .planned: .secondary
        }
    }
}
