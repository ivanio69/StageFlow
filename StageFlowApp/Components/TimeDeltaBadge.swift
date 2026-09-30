import SwiftUI

struct TimeDeltaBadge: View {
    let seconds: TimeInterval

    private var isDelayed: Bool { seconds > 30 }
    private var isAhead: Bool { seconds < -30 }

    var body: some View {
        Text(ScheduleEngine.formattedDelta(seconds))
            .font(.system(.headline, design: .rounded, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
            .foregroundStyle(isDelayed ? .orange : (isAhead ? .green : .secondary))
    }
}
