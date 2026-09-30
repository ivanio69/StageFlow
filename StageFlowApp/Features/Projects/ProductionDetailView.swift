import SwiftUI

struct ProductionDetailView: View {
    let production: Production
    @State private var isAddingRehearsal = false

    var body: some View {
        List {
            if production.rehearsals.isEmpty {
                ContentUnavailableView(
                    "Нет репетиций",
                    systemImage: "calendar.badge.plus",
                    description: Text("Добавьте первую репетицию и разбейте её на блоки.")
                )
            } else {
                ForEach(production.rehearsals.sorted(by: { $0.scheduledStart < $1.scheduledStart })) { rehearsal in
                    NavigationLink {
                        RehearsalDetailView(rehearsal: rehearsal)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(rehearsal.title)
                                .font(.headline)
                            Text(rehearsal.scheduledStart.formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle(production.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Репетиция", systemImage: "plus") {
                    isAddingRehearsal = true
                }
            }
        }
        .sheet(isPresented: $isAddingRehearsal) {
            AddRehearsalView(production: production)
        }
    }
}
