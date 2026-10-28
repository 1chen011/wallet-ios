import SwiftUI
import SwiftData

struct ReviewDraftView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \StoredCategory.sortOrder)
    private var categories: [StoredCategory]

    let draft: StoredDraft

    @State private var amount = ""
    @State private var merchant = ""
    @State private var notes = ""
    @State private var selectedCategoryId: String?
    @State private var date = Date()
    @State private var showCategories = false
    @State private var errorMessage: String?

    private var activeCategories: [StoredCategory] {
        categories.filter { !$0.isArchived }
    }

    private var canConfirm: Bool {
        CaptureAmount.parse(amount) != nil &&
        activeCategories.contains { $0.id == selectedCategoryId }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Review captured information") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("reviewAmount")
                    TextField("Merchant (optional)", text: $merchant)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }

                Section("Category") {
                    Button {
                        showCategories = true
                    } label: {
                        HStack {
                            Text(activeCategories.first(where: { $0.id == selectedCategoryId })?.name ?? "Choose category")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .accessibilityIdentifier("reviewCategory")
                }

                Section("Description · Optional") {
                    TextField("What was this for?", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button(action: confirm) {
                        Text("Confirm & Save Expense")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canConfirm)
                    .accessibilityIdentifier("confirmDraftButton")
                } footer: {
                    Text("Only confirmed expenses count toward Recorded Spending.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(WalletTheme.background(colorScheme))
            .navigationTitle("Review Draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showCategories) {
                CategorySelectionView(selectedCategoryId: $selectedCategoryId)
            }
            .onAppear {
                amount = CaptureAmount.inputValue(draft.amountInMinorUnits)
                merchant = draft.merchant ?? ""
                notes = draft.expenseDescription ?? ""
                date = draft.date
            }
            .alert("Could Not Confirm Draft", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
            .tint(WalletTheme.navy)
        }
    }

    private func confirm() {
        guard let cents = CaptureAmount.parse(amount),
              let categoryId = selectedCategoryId,
              activeCategories.contains(where: { $0.id == categoryId }) else { return }

        // One save for both operations; rollback leaves the draft available if saving fails.
        let transaction = Transaction(
            type: .expense,
            amountInMinorUnits: cents,
            currencyCode: draft.currencyCode,
            categoryId: categoryId,
            date: date,
            merchant: trimmedOrNil(merchant),
            expenseDescription: trimmedOrNil(notes)
        )
        modelContext.insert(StoredTransaction(transaction: transaction))
        modelContext.delete(draft)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func trimmedOrNil(_ value: String) -> String? {
        let result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
}
