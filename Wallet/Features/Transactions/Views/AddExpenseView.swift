
import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \StoredCategory.sortOrder) private var categories: [StoredCategory]
    @Query(sort: \StoredTransaction.date, order: .reverse) private var previousTransactions: [StoredTransaction]

    let transactionToEdit: Transaction?
    let initialDate: Date
    let onSave: (Transaction) -> Void

    init(transactionToEdit: Transaction? = nil, initialDate: Date = .now, onSave: @escaping (Transaction) -> Void) {
        self.transactionToEdit = transactionToEdit
        self.initialDate = initialDate
        self.onSave = onSave
    }

    @State private var amount = ""
    @State private var selectedCategoryId: String? = nil
    @State private var selectedDate = Date()
    @State private var showingAllCategories = false
    @State private var merchant = ""
    @State private var expenseDescription = ""
    @State private var showingDescription = false

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
            let padded = digits.count == 1
                ? digits + "0"
                : digits

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

    private var activeCategories: [StoredCategory] { categories.filter { !$0.isArchived } }
    private var quickCategories: [StoredCategory] {
        // Most recently used distinct categories first; no new category is required.
        var seen = Set<String>()
        let recentIds = previousTransactions.compactMap { transaction -> String? in
            guard activeCategories.contains(where: { $0.id == transaction.categoryId }),
                  seen.insert(transaction.categoryId).inserted else { return nil }
            return transaction.categoryId
        }
        let ids = recentIds + activeCategories.map(\.id).filter { !seen.contains($0) }
        return Array(ids.prefix(4)).compactMap { id in activeCategories.first { $0.id == id } }
    }

    private var merchantSuggestions: [String] {
        let query = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        var seen = Set<String>()
        return Array(previousTransactions.compactMap { stored -> String? in
            guard let value = stored.merchant?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty, value.localizedStandardContains(query) else { return nil }
            let key = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            return seen.insert(key).inserted ? value : nil
        }.prefix(4))
    }

    private var normalizedMerchant: String? {
        let value = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        // Reuse the original display spelling, regardless of input capitalization.
        return previousTransactions.compactMap(\.merchant).first {
            $0.compare(value, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        } ?? value
    }
    private var suggestedCategory: StoredCategory? {
        let input = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }

        let matchedTransaction = previousTransactions.first { transaction in
            guard let recordedMerchant = transaction.merchant?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return false
            }
            return recordedMerchant.compare(
                input,
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            ) == .orderedSame && activeCategories.contains { $0.id == transaction.categoryId }
        }

        guard let matchedTransaction else { return nil }
        return activeCategories.first { $0.id == matchedTransaction.categoryId }
    }

    private var canSave: Bool {
        parsedAmount != nil && (activeCategories.contains { $0.id == selectedCategoryId }
            || (transactionToEdit != nil && selectedCategoryId == transactionToEdit?.categoryId))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    amountSection
                    merchantSection
                    categorySection
                    dateSection
                    descriptionSection
                }
                .padding(.horizontal, WalletTheme.horizontalPadding)
                .padding(.top, 28)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(WalletTheme.background(colorScheme))
            .navigationTitle(transactionToEdit == nil ? "Add Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
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
            .sheet(isPresented: $showingAllCategories) {
                CategorySelectionView(
                    selectedCategoryId: $selectedCategoryId
                )
            }
        }
        .tint(WalletTheme.navy)
        .onAppear {
            selectedDate = initialDate
            guard let transactionToEdit else { return }
            amount = NSDecimalNumber(decimal: Decimal(transactionToEdit.amountInMinorUnits) / 100).stringValue
            selectedCategoryId = transactionToEdit.categoryId
            selectedDate = transactionToEdit.date
            merchant = transactionToEdit.merchant ?? ""
            expenseDescription = transactionToEdit.expenseDescription ?? ""
            showingDescription = !expenseDescription.isEmpty
        }
    }

    // MARK: - Amount

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("AMOUNT")

            VStack(alignment: .leading, spacing: 12) {
                Text("How much did you spend?")
                    .font(.subheadline)
                    .foregroundStyle(
                        WalletTheme.secondaryText(colorScheme)
                    )

                HStack(
                    alignment: .firstTextBaseline,
                    spacing: 10
                ) {
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
                        .accessibilityIdentifier(
                            "expenseAmountField"
                        )
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

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("CATEGORY")

                Spacer()

                Button {
                    showingAllCategories = true
                } label: {
                    HStack(spacing: 5) {
                        Text("Search All")

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WalletTheme.navy)
                }
                .accessibilityIdentifier("searchAllCategories")
            }

            if let suggestedCategory,
               selectedCategoryId != suggestedCategory.id {
                Button {
                    selectedCategoryId = suggestedCategory.id
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(WalletTheme.gold)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Suggested from your previous purchases")
                                .font(.caption)
                                .foregroundStyle(WalletTheme.secondaryText(colorScheme))
                            Text(suggestedCategory.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(WalletTheme.primaryText(colorScheme))
                        }
                        Spacer()
                        Text("Use")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WalletTheme.navy)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(WalletTheme.navy)
                    }
                    .padding(13)
                    .background(
                        WalletTheme.gold.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("useSuggestedCategory")
            }

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 9),
                    count: 4
                ),
                spacing: 10
            ) {
                ForEach(
                    quickCategories
                ) { category in
                    categoryButton(category)
                }
            }

            if let selectedCategoryId,
               let selected = categories.first(where: { $0.id == selectedCategoryId }),
               !quickCategories.contains(where: { $0.id == selectedCategoryId }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(WalletTheme.navy)

                    Text("Selected: \(selected.name)")
                        .font(.subheadline)
                        .foregroundStyle(
                            WalletTheme.primaryText(colorScheme)
                        )

                    Spacer()
                }
                .padding(13)
                .background(
                    WalletTheme.surface(colorScheme),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
        }
    }

    private func categoryButton(
        _ category: StoredCategory
    ) -> some View {
        let isSelected = selectedCategoryId == category.id

        return Button {
            selectedCategoryId = category.id
        } label: {
            VStack(spacing: 9) {
                Image(systemName: category.iconName)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(WalletTheme.navy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        category.color,
                        in: RoundedRectangle(cornerRadius: 16)
                    )

                Text(category.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        WalletTheme.primaryText(colorScheme)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(7)
            .frame(maxWidth: .infinity)
            .background(
                isSelected
                    ? WalletTheme.gold.opacity(0.22)
                    : WalletTheme.surface(colorScheme),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isSelected ? WalletTheme.gold : .clear,
                        lineWidth: 2
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    // MARK: - Merchant & optional description

    private var merchantSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("MERCHANT · OPTIONAL")
            VStack(alignment: .leading, spacing: 8) {
                TextField("e.g. CoCo, Steam, Amazon", text: $merchant)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("merchantField")
                ForEach(merchantSuggestions, id: \.self) { suggestion in
                    Button {
                        merchant = suggestion
                    } label: {
                        HStack {
                            Image(systemName: "arrow.turn.down.right")
                            Text(suggestion)
                            Spacer()
                        }
                        .font(.subheadline)
                        .foregroundStyle(WalletTheme.primaryText(colorScheme))
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .background(WalletTheme.surface(colorScheme), in: RoundedRectangle(cornerRadius: WalletTheme.cornerRadius))
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation { showingDescription.toggle() }
            } label: {
                HStack {
                    sectionTitle("DESCRIPTION · OPTIONAL")
                    Spacer()
                    Image(systemName: showingDescription ? "chevron.up" : "chevron.down")
                }
            }
            .buttonStyle(.plain)
            if showingDescription {
                TextField("What was this for?", text: $expenseDescription, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(18)
                    .background(WalletTheme.surface(colorScheme), in: RoundedRectangle(cornerRadius: WalletTheme.cornerRadius))
                    .accessibilityIdentifier("expenseDescriptionField")
            }
        }
    }

    // MARK: - Date

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

    // MARK: - Save

    private var saveButton: some View {
        Button {
            saveExpense()
        } label: {
            Text(transactionToEdit == nil ? "Save Expense" : "Save Changes")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .foregroundStyle(WalletTheme.navy)
                .background(
                    canSave
                        ? WalletTheme.gold
                        : WalletTheme.gold.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 17)
                )
        }
        .disabled(!canSave)
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
        guard let amountInMinorUnits = parsedAmount,
              let categoryId = selectedCategoryId else {
            return
        }

        let transaction = Transaction(
            id: transactionToEdit?.id ?? UUID(),
            type: transactionToEdit?.type ?? .expense,
            amountInMinorUnits: amountInMinorUnits,
            currencyCode: transactionToEdit?.currencyCode ?? "CAD",
            categoryId: categoryId,
            date: selectedDate,
            merchant: normalizedMerchant,
            expenseDescription: expenseDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : expenseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        onSave(transaction)
        dismiss()
    }
}

#Preview {
    AddExpenseView(onSave: { _ in })
        .modelContainer(for: [StoredCategory.self, StoredTransaction.self], inMemory: true)
}
