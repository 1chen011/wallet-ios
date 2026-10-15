
import SwiftUI

struct TransactionRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let transaction: Transaction

    private var categoryName: String {
        ExpenseCategory.name(for: transaction.categoryId)
    }

    private var categoryIcon: String {
        switch transaction.categoryId {
        case "food": return "fork.knife"
        case "transportation": return "car.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "ticket.fill"
        case "housing": return "house.fill"
        case "bills": return "doc.text.fill"
        default: return "square.grid.2x2.fill"
        }
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
