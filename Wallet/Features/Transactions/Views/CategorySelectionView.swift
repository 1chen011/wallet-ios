import SwiftUI
import SwiftData

struct CategorySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Binding var selectedCategoryId: String?
    @Query(sort: \StoredCategory.sortOrder) private var categories: [StoredCategory]
    @State private var searchText = ""
    @State private var showingCreate = false

    private var filtered: [StoredCategory] {
        categories.filter { !$0.isArchived && (searchText.isEmpty || $0.name.localizedStandardContains(searchText)) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { category in
                    Button {
                        selectedCategoryId = category.id
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: category.iconName)
                                .foregroundStyle(WalletTheme.navy)
                                .frame(width: 42, height: 42)
                                .background(category.color, in: RoundedRectangle(cornerRadius: 13))
                            Text(category.name).foregroundStyle(WalletTheme.primaryText(scheme))
                            Spacer()
                            if selectedCategoryId == category.id { Image(systemName: "checkmark.circle.fill") }
                        }
                    }
                }
                if filtered.isEmpty { ContentUnavailableView.search(text: searchText) }
                Section { Button { showingCreate = true } label: { Label("Create Category", systemImage: "plus.circle") } }
            }
            .scrollContentBackground(.hidden)
            .background(WalletTheme.background(scheme))
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search categories")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showingCreate) {
                CreateCategoryView { id in selectedCategoryId = id; dismiss() }
            }
        }
        .tint(WalletTheme.navy)
    }
}
