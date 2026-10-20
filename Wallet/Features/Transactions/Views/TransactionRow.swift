
import SwiftUI
import SwiftData

struct TransactionRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let transaction: Transaction

    @Query private var categories: [StoredCategory]

    private var category: StoredCategory? {
        categories.first { $0.id == transaction.categoryId }
    }

    private var categoryName: String {
        category?.name ?? ExpenseCategory.category(for: transaction.categoryId)?.name ?? "Uncategorized"
    }

    private var categoryIcon: String {
        category?.iconName ?? ExpenseCategory.category(for: transaction.categoryId)?.iconName ?? "tag.fill"
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: categoryIcon)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(WalletTheme.gold)
                .frame(width: 48, height: 48)
                .background(
                    WalletTheme.navy.opacity(
                        colorScheme == .dark ? 0.8 : 1
                    ),
                    in: RoundedRectangle(cornerRadius: 15)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(categoryName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        WalletTheme.primaryText(colorScheme)
                    )

                Text(
                    transaction.date,
                    format: .dateTime
                        .month(.abbreviated)
                        .day()
                        .year()
                )
                .font(.caption)
                .foregroundStyle(
                    WalletTheme.secondaryText(colorScheme)
                )
            }

            Spacer(minLength: 8)

            Text(transaction.formattedAmount)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    WalletTheme.primaryText(colorScheme)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(15)
        .background(
            WalletTheme.surface(colorScheme),
            in: RoundedRectangle(
                cornerRadius: WalletTheme.cornerRadius
            )
        )
        .accessibilityElement(children: .combine)
    }
}
