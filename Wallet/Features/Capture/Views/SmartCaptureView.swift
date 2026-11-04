import SwiftUI
import SwiftData
import PhotosUI

struct SmartCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var amount = ""
    @State private var merchant = ""
    @State private var currencyCode = "CAD"
    @State private var date = Date()
    @State private var recognizedLines: [String] = []
    @State private var warnings: [String] = []
    @State private var isProcessing = false
    @State private var didScan = false
    @State private var errorMessage: String?

    private var cleanMerchant: String? {
        let value = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private var canSave: Bool {
        !isProcessing && didScan && (CaptureAmount.parse(amount) != nil || cleanMerchant != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(didScan ? "Choose Another Screenshot" : "Choose Payment Screenshot", systemImage: "photo.on.rectangle")
                    }
                    .disabled(isProcessing)
                    if isProcessing { ProgressView("Recognizing screenshot locally…") }
                } footer: {
                    Text("Images are processed on this device and are not saved or uploaded by Wallet.")
                }

                if didScan {
                    Section("Review before saving") {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("smartCaptureAmount")
                        Picker("Currency", selection: $currencyCode) {
                            Text("CAD").tag("CAD")
                            Text("USD").tag("USD")
                            Text("CNY").tag("CNY")
                        }
                        TextField("Merchant (optional)", text: $merchant)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier("smartCaptureMerchant")
                        DatePicker("Purchase date", selection: $date, in: ...Date(), displayedComponents: .date)
                    }
                    if !warnings.isEmpty {
                        Section("Please check") {
                            ForEach(warnings, id: \.self) { warning in
                                Label(warning, systemImage: "exclamationmark.circle")
                                    .font(.footnote)
                            }
                        }
                    }
                    Section {
                        Button(action: saveDraft) {
                            Label("Save to Capture Inbox", systemImage: "tray.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(!canSave)
                        .accessibilityIdentifier("saveSmartCaptureDraft")
                    } footer: {
                        Text("This creates a draft, not a confirmed expense. Category can be selected later.")
                    }
                    if !recognizedLines.isEmpty {
                        Section("Recognized text · For reference") {
                            Text(recognizedLines.joined(separator: "\n"))
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(WalletTheme.background(colorScheme))
            .navigationTitle("Smart Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem else { return }
                Task { await scan(newItem) }
            }
            .alert("Smart Capture", isPresented: Binding(
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

    @MainActor
    private func scan(_ item: PhotosPickerItem) async {
        isProcessing = true
        didScan = false
        recognizedLines = []
        warnings = []
        amount = ""
        merchant = ""
        defer { isProcessing = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Could not load the selected screenshot."
                return
            }
            let lines = try await ScreenshotOCRService.recognize(imageData: data)
            let result = ExpenseExtractionService.extract(lines: lines)
            recognizedLines = lines
            amount = result.amount
            merchant = result.merchant
            currencyCode = result.currencyCode
            date = result.date ?? .now
            warnings = result.warnings
            didScan = true
        } catch {
            // Keep form available for manual correction even if OCR fails.
            warnings = [error.localizedDescription]
            didScan = true
        }
    }

    private func saveDraft() {
        guard canSave else { return }
        let draft = StoredDraft(
            amountInMinorUnits: CaptureAmount.parse(amount),
            currencyCode: currencyCode,
            merchant: cleanMerchant,
            date: date
        )
        modelContext.insert(draft)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = "Could not save draft: \(error.localizedDescription)"
        }
    }
}
