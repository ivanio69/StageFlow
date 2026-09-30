import SwiftUI

struct BlockRow: View {
    let block: RehearsalBlock

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(block.title)
                    .font(.headline)
                Text("\(block.plannedStart.formatted(date: .omitted, time: .shortened))–\(block.plannedEnd.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: icon)
                .foregroundStyle(iconStyle)
        }
        .padding(.vertical, 4)
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
