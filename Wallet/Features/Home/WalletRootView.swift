import SwiftUI
import SwiftData

// The root navigator stays in the main Wallet app target.
enum WalletTab: Hashable {
    case home, activity, inbox, insights
}

struct WalletRootView: View {
    let initialQuickAddRequest: Bool

    @State private var selection: WalletTab = .home
    @State private var showingAddExpense = false
    @State private var isQuickAdd = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var saveError = false

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                HomeView(
                    onAdd: { showingAddExpense = true },
                    onActivity: { selection = .activity },
                    onInbox: { selection = .inbox }
                )
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(WalletTab.home)

            NavigationStack {
                ActivityView(onAdd: { showingAddExpense = true }, onSave: saveTransaction)
            }
            .tabItem { Label("Activity", systemImage: "list.bullet.rectangle") }
            .tag(WalletTab.activity)

            NavigationStack { CaptureInboxView() }
                .tabItem { Label("Inbox", systemImage: "tray") }
                .tag(WalletTab.inbox)

            NavigationStack { InsightsView() }
                .tabItem { Label("Insights", systemImage: "chart.bar") }
                .tag(WalletTab.insights)
        }
        .tint(WalletTheme.gold)
        .sheet(isPresented: $showingAddExpense, onDismiss: { isQuickAdd = false }) {
            AddExpenseView(focusAmountOnAppear: isQuickAdd, onSave: saveTransaction)
        }
        .onAppear {
            if initialQuickAddRequest { openQuickAdd() }
            consumeQuickAddRequest()
        }
        .onReceive(NotificationCenter.default.publisher(for: .walletQuickAddRequested)) { _ in
            openQuickAdd()
        }
        .onChange(of: initialQuickAddRequest) { _, requested in
            if requested { openQuickAdd() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { consumeQuickAddRequest() }
        }
        .alert("Unable to Save Expense", isPresented: $saveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please try again. The expense was not saved.")
        }
    }

    private func consumeQuickAddRequest() {
        guard UserDefaults.standard.bool(forKey: QuickAddLaunchIntent.requestKey) else { return }
        UserDefaults.standard.removeObject(forKey: QuickAddLaunchIntent.requestKey)
        openQuickAdd()
    }

    private func openQuickAdd() {
        selection = .home
        isQuickAdd = true
        showingAddExpense = true
    }

    private func saveTransaction(_ transaction: Transaction) {
        modelContext.insert(StoredTransaction(transaction: transaction))
        do { try modelContext.save() }
        catch { modelContext.rollback(); saveError = true }
    }
}
