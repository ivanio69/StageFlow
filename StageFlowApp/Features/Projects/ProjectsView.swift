import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Production.createdAt, order: .reverse) private var productions: [Production]
    @State private var isAddingProduction = false

    var body: some View {
        NavigationStack {
            Group {
                if productions.isEmpty {
                    ContentUnavailableView(
                        "Нет постановок",
                        systemImage: "theatermasks",
                        description: Text("Создайте проект и добавьте первый график репетиции.")
                    )
                } else {
                    List {
                        ForEach(productions) { production in
                            NavigationLink {
                                ProductionDetailView(production: production)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(production.title)
                                        .font(.headline)
                                    Text("Репетиций: \(production.rehearsals.count)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("StageFlow")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Добавить", systemImage: "plus") {
                        isAddingProduction = true
                    }
                }
            }
            .sheet(isPresented: $isAddingProduction) {
                AddProductionView()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(productions[index])
        }
    }
}
