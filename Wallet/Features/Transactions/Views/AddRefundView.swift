import SwiftUI
import SwiftData

struct AddRefundView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let transaction: StoredTransaction
    let refundedAlready: Int64

    @State private var amount = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var errorMessage: String?

    private var remaining: Int64 {
        max(0, transaction.amountInMinorUnits - refundedAlready)
    }

    private var parsedAmount: Int64? {
        let value = amount.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard value.range(of: #"^[0-9]+(\.[0-9]{1,2})?$"#, options: .regularExpression) != nil else { return nil }
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard let whole = Int64(parts[0]) else { return nil }
        let fraction: Int64
        if parts.count > 1 {
            let digits = String(parts[1]); fraction = Int64(digits.count == 1 ? digits + "0" : digits) ?? -1
        } else { fraction = 0 }
        let (base, overflow1) = whole.multipliedReportingOverflow(by: 100)
        guard !overflow1 else { return nil }
        let (total, overflow2) = base.addingReportingOverflow(fraction)
        return !overflow2 && total > 0 && total <= remaining ? total : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Received Refund") {
                    TextField("Amount (CAD)", text: $amount)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("refundAmountField")
                    Text("Available to refund: \(money(remaining))")
                        .font(.caption).foregroundStyle(.secondary)
                    DatePicker("Date received", selection: $date, in: ...Date(), displayedComponents: .date)
                    TextField("Note · Optional", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    Button("Save Received Refund") { save() }
                        .fontWeight(.semibold)
                        .disabled(parsedAmount == nil)
                        .accessibilityIdentifier("saveRefundButton")
                } footer: {
                    Text("Only record a refund after the money has actually been returned. Refunds reduce net spending, not income.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(WalletTheme.background(colorScheme))
            .navigationTitle("Add Refund")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Unable to Save Refund", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "Try again.") }
            .tint(WalletTheme.navy)
        }
    }

    private func money(_ cents: Int64) -> String {
        (Decimal(cents) / 100).formatted(.currency(code: transaction.currencyCode))
    }

    private func save() {
        guard let cents = parsedAmount, transaction.paymentStatus == .completed else { return }
        let refund = StoredRefund(transactionId: transaction.id, amountInMinorUnits: cents, currencyCode: transaction.currencyCode, date: date, note: note.isEmpty ? nil : note)
        modelContext.insert(refund)
        do { try modelContext.save(); dismiss() }
        catch { modelContext.rollback(); errorMessage = error.localizedDescription }
    }
}
