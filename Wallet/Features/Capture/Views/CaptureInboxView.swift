import SwiftUI
import SwiftData

struct CaptureInboxView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredDraft.createdAt, order: .reverse)
    private var drafts: [StoredDraft]

    @State private var showingQuickCapture = false
    @State private var selectedDraft: StoredDraft?
    @State private var draftToDelete: StoredDraft?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("Save a detail now, finish the expense later. Drafts do not affect your spending totals.")
                    .font(.subheadline)
                    .foregroundStyle(WalletTheme.secondaryText(colorScheme))
                    .listRowBackground(WalletTheme.surface(colorScheme))
            }

            if drafts.isEmpty {
                ContentUnavailableView("Inbox is empty", systemImage: "tray", description: Text("Capture an amount or merchant to review later."))
                    .listRowBackground(Color.clear)
            } else {
                Section("To Review · \(drafts.count)") {
                    ForEach(drafts) { draft in
                        Button {
                            selectedDraft = draft
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(WalletTheme.gold)
                                    .frame(width: 36, height: 36)
                                    .background(WalletTheme.navy, in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(draft.merchant ?? "Untitled capture")
                                        .font(.headline)
                                        .foregroundStyle(WalletTheme.primaryText(colorScheme))
                                    Text(draft.date, format: .dateTime.month(.abbreviated).day().year())
                                        .font(.caption)
                                        .foregroundStyle(WalletTheme.secondaryText(colorScheme))
                                }
                                Spacer()
                                Text(draft.formattedAmount)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(WalletTheme.primaryText(colorScheme))
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("draftRow_\(draft.id)")
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                draftToDelete = draft
                            }
                        }
                        .listRowBackground(WalletTheme.surface(colorScheme))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(WalletTheme.background(colorScheme))
        .navigationTitle("Capture Inbox")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingQuickCapture = true
                } label: {
                    Label("Quick Capture", systemImage: "plus")
                }
                .accessibilityIdentifier("quickCaptureButton")
            }
        }
        .sheet(isPresented: $showingQuickCapture) {
            QuickCaptureView()
        }
        .sheet(item: $selectedDraft) { draft in
            ReviewDraftView(draft: draft)
        }
        .confirmationDialog("Delete this draft?", isPresented: Binding(
            get: { draftToDelete != nil },
            set: { if !$0 { draftToDelete = nil } }
        )) {
            Button("Delete Draft", role: .destructive) { deleteDraft() }
            Button("Cancel", role: .cancel) { draftToDelete = nil }
        } message: {
            Text("This won't affect your recorded spending.")
        }
        .alert("Could Not Delete Draft", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .tint(WalletTheme.navy)
    }

    private func deleteDraft() {
        guard let draftToDelete else { return }
        modelContext.delete(draftToDelete)
        do {
            try modelContext.save()
            self.draftToDelete = nil
        } catch {
            modelContext.rollback()
            self.draftToDelete = nil
            errorMessage = error.localizedDescription
        }
    }
}
