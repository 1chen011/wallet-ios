import SwiftUI
import SwiftData

@main
struct WalletApp: App {
    var body: some Scene {
        WindowGroup { WalletLaunchView() }
            .modelContainer(for: [StoredTransaction.self, StoredCategory.self])
    }
}

private struct WalletLaunchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var ready = false
    @State private var startupError: String?

    var body: some View {
        Group {
            if ready { HomeView() }
            else if let startupError {
                ContentUnavailableView("Unable to Load Categories", systemImage: "exclamationmark.triangle", description: Text(startupError))
            } else { ProgressView("Preparing Wallet…") }
        }
        .task {
            guard !ready else { return }
            do { try CategoryCatalog.seedIfNeeded(context: modelContext); ready = true }
            catch { startupError = error.localizedDescription }
        }
    }
}
