
import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingAddExpense = false
    @State private var transactions: [Transaction] = []

    private var sortedTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }
    }

    private var totalSpent: Int64 {
        transactions
            .filter { $0.type == .expense }
            .reduce(Int64(0)) { $0 + $1.amountInMinorUnits }
    }

    private var formattedTotal: String {
        (Decimal(totalSpent) / 100)
            .formatted(.currency(code: "CAD"))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    summaryCard

                    transactionsSection
                }
                .padding(.horizontal, WalletTheme.horizontalPadding)
                .padding(.top, 28)
                .padding(.bottom, 30)
            }
            .background(WalletTheme.background(colorScheme))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                addExpenseButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView { transaction in
                    transactions.append(transaction)
                }
            }
        }
        .tint(WalletTheme.gold)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("WALLET")
                    .font(.system(
                        size: 13,
                        weight: .bold,
                        design: .rounded
                    ))
                    .tracking(3)
                    .foregroundStyle(WalletTheme.gold)

                Text("Your money, your rhythm.")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(
                        WalletTheme.primaryText(colorScheme)
                    )
            }

            Spacer()

            Image(systemName: "wallet.bifold.fill")
                .font(.system(size: 20))
                .foregroundStyle(WalletTheme.gold)
                .frame(width: 48, height: 48)
                .background(
                    WalletTheme.navy,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .accessibilityHidden(true)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(
                    "Recorded spending",
                    systemImage: "chart.bar.fill"
                )
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))

                Spacer()

                Text("CAD")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WalletTheme.gold)
            }

            Text(formattedTotal)
                .font(.system(
                    size: 37,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .contentTransition(.numericText())

            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(height: 1)

            HStack {
                Text("Transactions recorded")
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Text("\(transactions.count)")
                    .foregroundStyle(WalletTheme.gold)
                    .fontWeight(.bold)
            }
            .font(.system(size: 13))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    WalletTheme.navy,
                    Color(red: 0.14, green: 0.22, blue: 0.33)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26)
        )
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        WalletTheme.primaryText(colorScheme)
                    )

                Spacer()

                Text("\(transactions.count) entries")
                    .font(.caption)
                    .foregroundStyle(
                        WalletTheme.secondaryText(colorScheme)
                    )
            }

            if transactions.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(sortedTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 31))
                .foregroundStyle(WalletTheme.gold)

            Text("No expenses yet")
                .font(.headline)
                .foregroundStyle(
                    WalletTheme.primaryText(colorScheme)
                )

            Text("Your spending story starts here.")
                .font(.subheadline)
                .foregroundStyle(
                    WalletTheme.secondaryText(colorScheme)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(
            WalletTheme.surface(colorScheme),
            in: RoundedRectangle(
                cornerRadius: WalletTheme.cornerRadius
            )
        )
    }

    private var addExpenseButton: some View {
        Button {
            showingAddExpense = true
        } label: {
            Label("Add Expense", systemImage: "plus")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .foregroundStyle(WalletTheme.navy)
                .background(
                    WalletTheme.gold,
                    in: RoundedRectangle(cornerRadius: 17)
                )
        }
        .accessibilityIdentifier("addExpenseButton")
        .padding(.horizontal, WalletTheme.horizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(WalletTheme.background(colorScheme))
    }
}

#Preview {
    HomeView()
}
