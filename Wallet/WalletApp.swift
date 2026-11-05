import SwiftUI
import SwiftData

@main
struct WalletApp: App {
    var body: some Scene {
        WindowGroup { WalletLaunchView() }
            .modelContainer(for: [StoredTransaction.self, StoredCategory.self, StoredDraft.self, StoredRefund.self])
    }
}

private struct WalletLaunchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var ready = false
    @State private var startupError: String?
    @State private var wantsQuickAdd = false

    var body: some View {
        Group {
            if ready {
                WalletRootView(initialQuickAddRequest: wantsQuickAdd)
            } else if let startupError {
                ContentUnavailableView(
                    "Unable to Load Categories",
                    systemImage: "exclamationmark.triangle",
                    description: Text(startupError)
                )
            } else {
                ProgressView("Preparing Wallet…")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .walletQuickAddRequested)) { _ in
            wantsQuickAdd = true
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { consumeQuickAddRequest() }
        }
        .task {
            consumeQuickAddRequest()
            guard !ready else { return }
            do {
                try CategoryCatalog.seedIfNeeded(context: modelContext)
                ready = true
            } catch {
                startupError = error.localizedDescription
            }
        }
    }

    private func consumeQuickAddRequest() {
        guard UserDefaults.standard.bool(forKey: QuickAddLaunchIntent.requestKey) else { return }
        UserDefaults.standard.removeObject(forKey: QuickAddLaunchIntent.requestKey)
        wantsQuickAdd = true
    }
}
