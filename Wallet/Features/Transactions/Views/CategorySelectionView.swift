
import SwiftUI

struct CategorySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selectedCategoryId: String?

    @State private var searchText = ""

    private var filteredCategories: [ExpenseCategory] {
        guard !searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return ExpenseCategory.presets
        }

        return ExpenseCategory.presets.filter {
            $0.name.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    if filteredCategories.isEmpty {
                        ContentUnavailableView.search(
                            text: searchText
                        )
                    } else {
                        ForEach(filteredCategories) { category in
                            categoryRow(category)
                        }
                    }
                }
                .padding(.horizontal, WalletTheme.horizontalPadding)
                .padding(.vertical, 16)
            }
            .background(WalletTheme.background(colorScheme))
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: "Search categories"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(
                        WalletTheme.primaryText(colorScheme)
                    )
                }
            }
        }
        .tint(WalletTheme.navy)
    }

    private func categoryRow(
        _ category: ExpenseCategory
    ) -> some View {
        let isSelected = selectedCategoryId == category.id

        return Button {
            selectedCategoryId = category.id
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: category.iconName)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(WalletTheme.navy)
                    .frame(width: 48, height: 48)
                    .background(
                        category.color,
                        in: RoundedRectangle(cornerRadius: 15)
                    )

                Text(category.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        WalletTheme.primaryText(colorScheme)
                    )

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 21))
                        .foregroundStyle(WalletTheme.navy)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(
                            WalletTheme.secondaryText(colorScheme)
                        )
                }
            }
            .padding(13)
            .background(
                WalletTheme.surface(colorScheme),
                in: RoundedRectangle(
                    cornerRadius: WalletTheme.cornerRadius
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: WalletTheme.cornerRadius
                )
                .strokeBorder(
                    isSelected ? WalletTheme.gold : .clear,
                    lineWidth: 2
                )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var selectedCategoryId: String? = "food"

    CategorySelectionView(
        selectedCategoryId: $selectedCategoryId
    )
}

