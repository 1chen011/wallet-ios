import SwiftUI
import SwiftData

struct HomeView: View {
    let onAdd: () -> Void
    let onActivity: () -> Void
    let onInbox: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \StoredTransaction.date, order: .reverse) private var transactions: [StoredTransaction]
    @Query private var refunds: [StoredRefund]
    @Query private var drafts: [StoredDraft]
    @State private var selectedTransaction: StoredTransaction?
    @State private var showingCategories = false

    private var thisMonth: [StoredTransaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) && Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .year) }
    }
    private var confirmed: Int64 {
        thisMonth.filter { $0.typeRawValue == "expense" && $0.paymentStatus == .completed }
            .reduce(Int64(0)) { $0 + $1.amountInMinorUnits }
    }
    private var refunded: Int64 {
        let ids = Set(thisMonth.filter { $0.paymentStatus == .completed }.map(\.id))
        return refunds.filter { ids.contains($0.transactionId) }.reduce(Int64(0)) { $0 + $1.amountInMinorUnits }
    }
    private var pending: Int64 {
        thisMonth.filter { $0.typeRawValue == "expense" && $0.paymentStatus == .pending }
            .reduce(Int64(0)) { $0 + $1.amountInMinorUnits }
    }
    private func amount(_ value: Int64) -> String {
        (Decimal(value) / 100).formatted(.currency(code: "CAD"))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                HStack {
                    Text("Overview")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(WalletTheme.primaryText(colorScheme))
                    Spacer()
                    Button { showingCategories = true } label: {
                        Label("Manage", systemImage: "slider.horizontal.3")
                            .font(.subheadline.weight(.medium))
                    }
                    .accessibilityLabel("Manage categories")
                }

                summary

                if !drafts.isEmpty {
                    Button(action: onInbox) {
                        HStack(spacing: 12) {
                            Image(systemName: "tray.full")
                                .foregroundStyle(WalletTheme.gold)
                            Text("\(drafts.count) saved for later")
                                .foregroundStyle(WalletTheme.primaryText(colorScheme))
                            Spacer()
                            Text("Review").font(.subheadline.weight(.semibold))
                            Image(systemName: "chevron.right")
                        }
                        .padding(16)
                        .background(WalletTheme.surface(colorScheme), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Text("Recent transactions")
                        .font(.title3.bold())
                    Spacer()
                    Button("See all", action: onActivity)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(WalletTheme.primaryText(colorScheme))

                if transactions.isEmpty {
                    ContentUnavailableView("No expenses yet", systemImage: "creditcard", description: Text("Add your first expense to get started."))
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(transactions.prefix(3)) { stored in
                            Button { selectedTransaction = stored } label: {
                                TransactionRow(transaction: stored.transaction)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, WalletTheme.horizontalPadding)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(WalletTheme.background(colorScheme))
        .safeAreaInset(edge: .bottom) {
            Button(action: onAdd) {
                Label("Add Expense", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(WalletTheme.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(WalletTheme.gold, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, WalletTheme.horizontalPadding)
            .padding(.vertical, 9)
            .background(WalletTheme.background(colorScheme))
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedTransaction) { TransactionDetailView(storedTransaction: $0) }
        .sheet(isPresented: $showingCategories) {
            NavigationStack { CategoryManagementView() }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spent this month")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
            Text(amount(confirmed - refunded + pending))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if pending > 0 {
                Label("Includes \(amount(pending)) awaiting final amount", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Text(Date.now.formatted(.dateTime.month(.wide).year()))
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(WalletTheme.navy, in: RoundedRectangle(cornerRadius: 24))
    }
}
