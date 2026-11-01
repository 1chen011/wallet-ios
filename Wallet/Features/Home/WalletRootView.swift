import SwiftUI
import SwiftData

enum WalletTab: Hashable {
    case home, activity, inbox, insights
}

struct WalletRootView: View {
    @State private var selection: WalletTab = .home
    @State private var showingAddExpense = false
    @Environment(\.modelContext) private var modelContext
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
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(onSave: saveTransaction)
        }
        .alert("Unable to Save Expense", isPresented: $saveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please try again. The expense was not saved.")
        }
    }

    private func saveTransaction(_ transaction: Transaction) {
        modelContext.insert(StoredTransaction(transaction: transaction))
        do { try modelContext.save() }
        catch { modelContext.rollback(); saveError = true }
    }
}
