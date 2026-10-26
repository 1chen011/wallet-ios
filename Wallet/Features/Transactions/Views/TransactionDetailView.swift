import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var storedTransaction: StoredTransaction
    @Query private var categories: [StoredCategory]

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private var categoryName: String {
        categories.first(where: { $0.id == storedTransaction.categoryId })?.name
        ?? ExpenseCategory.category(for: storedTransaction.categoryId)?.name
        ?? "Uncategorized"
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
                        detailRow("Currency", value: storedTransaction.currencyCode)
                    }
                    .padding(20)
                    .background(WalletTheme.surface(colorScheme), in: RoundedRectangle(cornerRadius: WalletTheme.cornerRadius))

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

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Expense", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, WalletTheme.horizontalPadding)
            }
            .background(WalletTheme.background(colorScheme))
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
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
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Changes could not be saved. Please try again."
            showingError = true
        }
    }

    private func deleteTransaction() {
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
