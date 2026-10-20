import SwiftUI
import SwiftData

struct CreateCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [StoredCategory]
    @State private var name = ""
    @State private var errorMessage: String?
    @State private var selectedTemplateID: String?

    var editing: StoredCategory? = nil
    var onCreated: ((String) -> Void)? = nil

    private var cleanName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var duplicate: StoredCategory? {
        categories.first { $0.id != editing?.id && CategoryCatalog.normalized($0.name) == CategoryCatalog.normalized(cleanName) }
    }
    private var suggestions: [(id: String, name: String, icon: String, color: Int)] {
        CategoryCatalog.availableTemplates(excluding: categories)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Name") {
                    TextField("e.g. Shipping", text: $name)
                        .textInputAutocapitalization(.words)
                        .onChange(of: name) { _, newValue in
                            if let chosen = selectedTemplateID,
                               CategoryCatalog.templates.first(where: { $0.id == chosen })?.name != newValue {
                                selectedTemplateID = nil
                            }
                        }
                    if let duplicate {
                        Text("\(duplicate.name) already exists. Use the existing category instead.")
                            .foregroundStyle(.secondary).font(.footnote)
                    }
                }
                if editing == nil && !suggestions.isEmpty {
                    Section("Or choose a template") {
                        ForEach(suggestions, id: \.id) { template in
                            Button {
                                name = template.name
                                selectedTemplateID = template.id
                            } label: {
                                Label(template.name, systemImage: template.icon)
                            }
                        }
                    }
                }
                Section {
                    Label("Icon and color are automatically assigned.", systemImage: "sparkles")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(editing == nil ? "New Category" : "Rename Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(cleanName.isEmpty || duplicate != nil)
                }
            }
            .alert("Could Not Save", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "Please try again.") }
        }
        .tint(WalletTheme.navy)
        .onAppear { if let editing { name = editing.name } }
    }

    private func save() {
        guard !cleanName.isEmpty, duplicate == nil else { return }
        if let editing {
            editing.name = cleanName
        } else {
            let template = CategoryCatalog.templates.first { $0.id == selectedTemplateID }
            let new = StoredCategory(
                id: template?.id ?? UUID().uuidString,
                name: cleanName,
                iconName: template?.icon ?? "tag.fill",
                colorHex: template?.color ?? 0xE8E1F1,
                sortOrder: (categories.map(\.sortOrder).max() ?? 0) + 1
            )
            modelContext.insert(new)
            do {
                try modelContext.save()
                onCreated?(new.id)
                dismiss()
            } catch { modelContext.rollback(); errorMessage = error.localizedDescription }
            return
        }
        do { try modelContext.save(); dismiss() }
        catch { modelContext.rollback(); errorMessage = error.localizedDescription }
    }
}
