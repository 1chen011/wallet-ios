import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \StoredCategory.sortOrder) private var categories: [StoredCategory]
    @State private var showingCreate = false
    @State private var editing: StoredCategory?
    @State private var errorMessage: String?

    private var active: [StoredCategory] { categories.filter { !$0.isArchived } }
    private var archived: [StoredCategory] { categories.filter(\.isArchived) }

    var body: some View {
        List {
            Section("Your Categories") {
                ForEach(active) { category in row(category) }
            }
            Section {
                Button { showingCreate = true } label: {
                    Label("Add Category", systemImage: "plus.circle.fill")
                }
            }
            if !archived.isEmpty {
                Section("Archived") { ForEach(archived) { category in row(category) } }
            }
        }
        .scrollContentBackground(.hidden)
        .background(WalletTheme.background(scheme))
        .navigationTitle("Manage Categories")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreate) { CreateCategoryView() }
        .sheet(item: $editing) { category in CreateCategoryView(editing: category) }
        .alert("Could Not Save", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "Please try again.") }
    }

    private func row(_ category: StoredCategory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: category.iconName)
                .foregroundStyle(WalletTheme.navy)
                .frame(width: 38, height: 38)
                .background(category.color, in: RoundedRectangle(cornerRadius: 12))
            Text(category.name)
            Spacer()
            Menu {
                Button("Rename", systemImage: "pencil") { editing = category }
                Button(category.isArchived ? "Restore" : "Archive", systemImage: category.isArchived ? "arrow.uturn.backward" : "archivebox") {
                    category.isArchived.toggle()
                    do { try modelContext.save() }
                    catch { modelContext.rollback(); errorMessage = error.localizedDescription }
                }
            } label: { Image(systemName: "ellipsis.circle").font(.title3) }
        }
        .padding(.vertical, 3)
    }
}
