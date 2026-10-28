import SwiftUI
import SwiftData

struct QuickCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var amount = ""
    @State private var merchant = ""
    @State private var date = Date()
    @State private var errorMessage: String?

    private var cleanedMerchant: String? {
        let text = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    private var canCapture: Bool {
        CaptureAmount.parse(amount) != nil || cleanedMerchant != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount (optional)", text: $amount)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("captureAmount")
                    TextField("Merchant (optional)", text: $merchant)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("captureMerchant")
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                } header: {
                    Text("Capture what you know")
                } footer: {
                    Text("An amount or merchant is enough. You can complete the rest later.")
                }

                Section {
                    Button(action: saveDraft) {
                        Label("Save to Inbox", systemImage: "tray.and.arrow.down.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canCapture)
                    .accessibilityIdentifier("saveDraftButton")
                }
            }
            .scrollContentBackground(.hidden)
            .background(WalletTheme.background(colorScheme))
            .navigationTitle("Quick Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .tint(WalletTheme.navy)
            .alert("Could Not Save Draft", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    private func saveDraft() {
        guard canCapture else { return }
        let draft = StoredDraft(
            amountInMinorUnits: CaptureAmount.parse(amount),
            merchant: cleanedMerchant,
            date: date
        )
        modelContext.insert(draft)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
