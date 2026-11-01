import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query private var transactions: [StoredTransaction]
    @Query private var refunds: [StoredRefund]

    private var monthTransactions: [StoredTransaction] {
        transactions.filter {
            Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) &&
            Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .year)
        }
    }
    private var completed: [StoredTransaction] {
        monthTransactions.filter { $0.typeRawValue == "expense" && $0.paymentStatus == .completed }
    }
    private var refunded: Int64 {
        let ids = Set(completed.map(\.id))
        return refunds.filter { ids.contains($0.transactionId) }.reduce(0) { $0 + $1.amountInMinorUnits }
    }
    private var total: Int64 {
        completed.reduce(0) { $0 + $1.amountInMinorUnits } - refunded
    }
    private func money(_ value: Int64) -> String {
        (Decimal(value) / 100).formatted(.currency(code: "CAD"))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Confirmed spending this month")
                    .font(.subheadline)
                    .foregroundStyle(WalletTheme.secondaryText(colorScheme))
                Text(money(total))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(WalletTheme.primaryText(colorScheme))
                Text("After received refunds · Excludes pending payments and drafts")
                    .font(.caption)
                    .foregroundStyle(WalletTheme.secondaryText(colorScheme))
                Divider()
                Text("Transactions this month")
                    .font(.headline)
                Text("\(monthTransactions.count)")
                    .font(.title.bold())
                Text("More insights, including category breakdown and payday planning, will be added after the core navigation is tested.")
                    .font(.subheadline)
                    .foregroundStyle(WalletTheme.secondaryText(colorScheme))
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WalletTheme.surface(colorScheme), in: RoundedRectangle(cornerRadius: 20))
            .padding(WalletTheme.horizontalPadding)
        }
        .background(WalletTheme.background(colorScheme))
        .navigationTitle("Insights")
    }
}
