import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var storedTransaction: StoredTransaction
    @Query private var categories: [StoredCategory]
    @Query private var refunds: [StoredRefund]

    @State private var showingEdit = false
    @State private var showingRefund = false
    @State private var showingFinalize = false
    @State private var finalAmount = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private var categoryName: String {
        categories.first(where: { $0.id == storedTransaction.categoryId })?.name
        ?? ExpenseCategory.category(for: storedTransaction.categoryId)?.name
        ?? "Uncategorized"
    }

    private var linkedRefunds: [StoredRefund] {
        refunds.filter { $0.transactionId == storedTransaction.id }
            .sorted { $0.date > $1.date }
    }

    private var refundedAmount: Int64 { linkedRefunds.reduce(0) { $0 + $1.amountInMinorUnits } }
    private var netAmount: Int64 { storedTransaction.amountInMinorUnits - refundedAmount }

    private func money(_ cents: Int64) -> String {
        (Decimal(cents) / 100).formatted(.currency(code: storedTransaction.currencyCode))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 12) {
                        Text(storedTransaction.transaction.formattedAmount)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(WalletTheme.primaryText(colorScheme))
                        Text(categoryName)
                            .font(.headline)
                            .foregroundStyle(WalletTheme.secondaryText(colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 28)

                    VStack(spacing: 16) {
                        detailRow("Category", value: categoryName)
                        Divider()
                        detailRow("Date", value: storedTransaction.date.formatted(date: .abbreviated, time: .omitted))
                        Divider()
                        if let merchant = storedTransaction.merchant, !merchant.isEmpty {
                            detailRow("Merchant", value: merchant)
                            Divider()
                        }
                        if let description = storedTransaction.expenseDescription, !description.isEmpty {
                            detailRow("Description", value: description)
                            Divider()
                        }
                        if storedTransaction.paymentStatus != .completed {
                            detailRow("Payment", value: storedTransaction.paymentStatus.title)
                        }
                        if storedTransaction.paymentStatus == .completed && !linkedRefunds.isEmpty {
                            Divider()
                            detailRow("Refunded", value: money(refundedAmount))
                            Divider()
                            detailRow("Net spending", value: money(netAmount))
                        }
                    }
                    .padding(20)
                    .background(WalletTheme.surface(colorScheme), in: RoundedRectangle(cornerRadius: WalletTheme.cornerRadius))

                    if storedTransaction.paymentStatus == .pending {
                        Button {
                            finalAmount = NSDecimalNumber(decimal: Decimal(storedTransaction.amountInMinorUnits) / 100).stringValue
                            showingFinalize = true
                        } label: {
                            Label("Confirm final amount", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                    }

                    if storedTransaction.paymentStatus == .completed && storedTransaction.typeRawValue == "expense" && netAmount > 0 {
                        Button { showingRefund = true } label: {
                            Label("Record a refund", systemImage: "arrow.uturn.backward")
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                    }

                    if !linkedRefunds.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Refund History").font(.headline)
                            ForEach(linkedRefunds) { refund in
                                HStack {
                                    Text(refund.date, format: .dateTime.month(.abbreviated).day().year())
                                    Spacer()
                                    Text("+" + money(refund.amountInMinorUnits))
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(18)
                        .background(WalletTheme.surface(colorScheme), in: RoundedRectangle(cornerRadius: WalletTheme.cornerRadius))
                    }

                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit Expense", systemImage: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .foregroundStyle(WalletTheme.navy)
                            .background(WalletTheme.gold, in: RoundedRectangle(cornerRadius: 17))
                    }


                }
                .padding(.horizontal, WalletTheme.horizontalPadding)
            }
            .background(WalletTheme.background(colorScheme))
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Expense", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingRefund) {
                AddRefundView(transaction: storedTransaction, refundedAlready: refundedAmount)
            }
            .alert("Finalize Payment", isPresented: $showingFinalize) {
                TextField("Final amount", text: $finalAmount).keyboardType(.decimalPad)
                Button("Confirm") { finalizePayment() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Confirm the final amount after settlement. This will replace the pending estimate, not add a second expense.")
            }
            .sheet(isPresented: $showingEdit) {
                AddExpenseView(transactionToEdit: storedTransaction.transaction) { updated in
                    updateTransaction(updated)
                }
            }
            .confirmationDialog(
                "Delete this expense?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Expense", role: .destructive) {
                    deleteTransaction()
                }
            } message: {
                Text("This transaction will be permanently deleted.")
            }
            .alert("Unable to Save Changes", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .tint(WalletTheme.gold)
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(WalletTheme.secondaryText(colorScheme))
            Spacer()
            Text(value).foregroundStyle(WalletTheme.primaryText(colorScheme))
        }
        .font(.subheadline)
    }

    private func updateTransaction(_ updated: Transaction) {
        guard updated.id == storedTransaction.id else { return }
        storedTransaction.amountInMinorUnits = updated.amountInMinorUnits
        storedTransaction.categoryId = updated.categoryId
        storedTransaction.date = updated.date
        storedTransaction.merchant = updated.merchant
        storedTransaction.expenseDescription = updated.expenseDescription
        // Completed expenses with received refunds cannot be changed back to pending/cancelled.
        if linkedRefunds.isEmpty { storedTransaction.paymentStatus = updated.paymentStatus }
        guard storedTransaction.amountInMinorUnits >= refundedAmount else {
            modelContext.rollback()
            errorMessage = "The amount cannot be below the total already refunded."
            showingError = true
            return
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Changes could not be saved. Please try again."
            showingError = true
        }
    }

    private func finalizePayment() {
        guard storedTransaction.paymentStatus == .pending else { return }
        let normalized = finalAmount.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^[0-9]+(\.[0-9]{1,2})?$"#, options: .regularExpression) != nil else {
            errorMessage = "Enter a valid amount (up to two decimal places)."
            showingError = true
            return
        }
        let parts = normalized.split(separator: ".", omittingEmptySubsequences: false)
        guard let whole = Int64(parts[0]) else { return }
        let digits = parts.count == 2 ? String(parts[1]) : ""
        let fraction = Int64(digits.isEmpty ? "0" : digits.count == 1 ? digits + "0" : digits) ?? 0
        let (base, overflow1) = whole.multipliedReportingOverflow(by: 100)
        guard !overflow1 else { return }
        let (total, overflow2) = base.addingReportingOverflow(fraction)
        guard !overflow2, total > 0 else {
            errorMessage = "Enter a positive final amount."
            showingError = true
            return
        }
        storedTransaction.amountInMinorUnits = total
        storedTransaction.paymentStatus = .completed
        do { try modelContext.save() }
        catch { modelContext.rollback(); errorMessage = error.localizedDescription; showingError = true }
    }

    private func deleteTransaction() {
        for refund in linkedRefunds { modelContext.delete(refund) }
        modelContext.delete(storedTransaction)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = "This expense could not be deleted. Please try again."
            showingError = true
        }
    }
}
