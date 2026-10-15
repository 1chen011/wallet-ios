
import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let onSave: (Transaction) -> Void

    @State private var amount = ""
    @State private var selectedCategoryId = "food"
    @State private var selectedDate = Date()

    private var parsedAmount: Int64? {
        let normalized = amount
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard normalized.range(
            of: #"^[0-9]+(\.[0-9]{1,2})?$"#,
            options: .regularExpression
        ) != nil else {
            return nil
        }

        let parts = normalized.split(
            separator: ".",
            omittingEmptySubsequences: false
        )

        guard let whole = Int64(parts[0]) else {
            return nil
        }

        let fractional: Int64

        if parts.count == 2 {
            let digits = String(parts[1])
            let padded = digits.count == 1 ? digits + "0" : digits

            guard let value = Int64(padded) else {
                return nil
            }

            fractional = value
        } else {
            fractional = 0
        }

        let (base, overflow1) =
            whole.multipliedReportingOverflow(by: 100)

        guard !overflow1 else {
            return nil
        }

        let (total, overflow2) =
            base.addingReportingOverflow(fractional)

        guard !overflow2, total > 0 else {
            return nil
        }

        return total
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    amountSection
                    categorySection
                    dateSection
                }
                .padding(.horizontal, WalletTheme.horizontalPadding)
                .padding(.top, 28)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(WalletTheme.background(colorScheme))
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(
                WalletTheme.background(colorScheme),
                for: .navigationBar
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(
                        WalletTheme.primaryText(colorScheme)
                    )
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                saveButton
            }
        }
        .tint(WalletTheme.gold)
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("AMOUNT")

            VStack(alignment: .leading, spacing: 12) {
                Text("How much did you spend?")
                    .font(.subheadline)
                    .foregroundStyle(
                        WalletTheme.secondaryText(colorScheme)
                    )

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("CA$")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(WalletTheme.gold)

                    TextField("0.00", text: $amount)
                        .font(.system(
                            size: 38,
                            weight: .semibold,
                            design: .rounded
                        ))
                        .keyboardType(.decimalPad)
                        .foregroundStyle(
                            WalletTheme.primaryText(colorScheme)
                        )
                        .accessibilityIdentifier("expenseAmountField")
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                WalletTheme.surface(colorScheme),
                in: RoundedRectangle(
                    cornerRadius: WalletTheme.cornerRadius
                )
            )
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("CATEGORY")

            VStack(alignment: .leading, spacing: 12) {
                Text("Choose a category")
                    .font(.subheadline)
                    .foregroundStyle(
                        WalletTheme.secondaryText(colorScheme)
                    )

                Picker(
                    "Category",
                    selection: $selectedCategoryId
                ) {
                    ForEach(ExpenseCategory.presets) { category in
                        Text(category.name)
                            .tag(category.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("expenseCategoryPicker")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                WalletTheme.surface(colorScheme),
                in: RoundedRectangle(
                    cornerRadius: WalletTheme.cornerRadius
                )
            )
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("DATE")

            DatePicker(
                "Transaction Date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .foregroundStyle(
                WalletTheme.primaryText(colorScheme)
            )
            .padding(20)
            .background(
                WalletTheme.surface(colorScheme),
                in: RoundedRectangle(
                    cornerRadius: WalletTheme.cornerRadius
                )
            )
        }
    }

    private var saveButton: some View {
        Button {
            saveExpense()
        } label: {
            Text("Save Expense")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .foregroundStyle(WalletTheme.navy)
                .background(
                    parsedAmount == nil
                        ? WalletTheme.gold.opacity(0.4)
                        : WalletTheme.gold,
                    in: RoundedRectangle(cornerRadius: 17)
                )
        }
        .disabled(parsedAmount == nil)
        .accessibilityIdentifier("saveExpenseButton")
        .padding(.horizontal, WalletTheme.horizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(WalletTheme.background(colorScheme))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .tracking(2)
            .foregroundStyle(
                WalletTheme.secondaryText(colorScheme)
            )
    }

    private func saveExpense() {
        guard let amountInMinorUnits = parsedAmount else {
            return
        }

        let transaction = Transaction(
            amountInMinorUnits: amountInMinorUnits,
            categoryId: selectedCategoryId,
            date: selectedDate
        )

        onSave(transaction)
        dismiss()
    }
}

#Preview {
    AddExpenseView(onSave: { _ in })
}
