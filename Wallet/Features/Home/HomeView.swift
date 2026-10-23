
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \StoredTransaction.date, order: .reverse)
    private var storedTransactions: [StoredTransaction]

    @State private var selectedTransaction: StoredTransaction?
    @State private var showingAddExpense = false
    @State private var showingCategoryManagement = false
    @State private var showingSaveError = false

    private var transactions: [Transaction] {
        storedTransactions.map { $0.transaction }
    }

    private var totalSpent: Int64 {
        transactions
            .filter { $0.type == .expense }
            .reduce(Int64(0)) {
                $0 + $1.amountInMinorUnits
            }
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
                .padding(
                    .horizontal,
                    WalletTheme.horizontalPadding
                )
                .padding(.top, 28)
                .padding(.bottom, 30)
            }
            .background(
                WalletTheme.background(colorScheme)
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                addExpenseButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedTransaction) { stored in
                TransactionDetailView(storedTransaction: stored)
            }
            .sheet(isPresented: $showingCategoryManagement) {
                NavigationStack { CategoryManagementView() }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView { transaction in
                    saveTransaction(transaction)
                }
            }
            .alert(
                "Unable to Save Expense",
                isPresented: $showingSaveError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your expense could not be saved. Please try again.")
            }
        }
        .tint(WalletTheme.gold)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("WALLET")
                    .font(
                        .system(
                            size: 13,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .tracking(3)
                    .foregroundStyle(WalletTheme.gold)

                Text("Your money, your rhythm.")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(
                        WalletTheme.primaryText(colorScheme)
                    )
            }

            Spacer()

            Button { showingCategoryManagement = true } label: {
                Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 20))
                .foregroundStyle(WalletTheme.gold)
                .frame(width: 48, height: 48)
                .background(
                    WalletTheme.navy,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .accessibilityLabel("Manage Categories")
            }
        }
    }

    // MARK: - Spending Summary

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
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(WalletTheme.gold)
            }

            Text(formattedTotal)
                .font(
                    .system(
                        size: 37,
                        weight: .bold,
                        design: .rounded
                    )
                )
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
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            LinearGradient(
                colors: [
                    WalletTheme.navy,
                    Color(
                        red: 0.14,
                        green: 0.22,
                        blue: 0.33
                    )
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26)
        )
    }

    // MARK: - Transaction History

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(
                        .system(
                            size: 20,
                            weight: .bold
                        )
                    )
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
                    ForEach(storedTransactions) { stored in
                        Button {
                            selectedTransaction = stored
                        } label: {
                            TransactionRow(transaction: stored.transaction)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("transactionRow_\(stored.id)")
                    }
                }
            }
        }
    }

    // MARK: - Empty State

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

    // MARK: - Add Expense Button

    private var addExpenseButton: some View {
        Button {
            showingAddExpense = true
        } label: {
            Label(
                "Add Expense",
                systemImage: "plus"
            )
            .font(
                .system(
                    size: 16,
                    weight: .semibold
                )
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .foregroundStyle(WalletTheme.navy)
            .background(
                WalletTheme.gold,
                in: RoundedRectangle(cornerRadius: 17)
            )
        }
        .accessibilityIdentifier("addExpenseButton")
        .padding(
            .horizontal,
            WalletTheme.horizontalPadding
        )
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            WalletTheme.background(colorScheme)
        )
    }

    // MARK: - SwiftData Persistence

    private func saveTransaction(
        _ transaction: Transaction
    ) {
        let storedTransaction = StoredTransaction(
            transaction: transaction
        )

        modelContext.insert(storedTransaction)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            showingSaveError = true

            print(
                "Failed to save transaction: \(error)"
            )
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(
            for: [StoredTransaction.self, StoredCategory.self],
            inMemory: true
        )
}
