import SwiftUI
import SwiftData

struct ActivityView: View {
    let onAdd: () -> Void
    let onSave: (Transaction) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \StoredTransaction.date, order: .reverse) private var transactions: [StoredTransaction]
    @State private var search = ""
    @State private var filter: Filter = .all
    @State private var calendar = false
    @State private var selection: StoredTransaction?

    private enum Filter: String, CaseIterable, Identifiable {
        case all = "All", pending = "Pending", completed = "Completed"
        var id: String { rawValue }
    }
    private var filtered: [StoredTransaction] {
        transactions.filter { item in
            let matchesStatus = filter == .all || (filter == .pending && item.paymentStatus == .pending) || (filter == .completed && item.paymentStatus == .completed)
            let matchesText = search.isEmpty || [item.merchant ?? "", item.expenseDescription ?? "", ExpenseCategory.category(for: item.categoryId)?.name ?? ""].contains { $0.localizedCaseInsensitiveContains(search) }
            return matchesStatus && matchesText
        }
    }
    private var groupedDays: [Date] {
        Array(Set(filtered.map { Calendar.current.startOfDay(for: $0.date) })).sorted(by: >)
    }

    var body: some View {
        List {
            Section {
                Picker("Status", selection: $filter) {
                    ForEach(Filter.allCases) { f in Text(f.rawValue).tag(f) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }
            if filtered.isEmpty {
                ContentUnavailableView("No matching transactions", systemImage: "list.bullet.rectangle", description: Text("Try another search or filter."))
                    .listRowBackground(Color.clear)
            }
            ForEach(groupedDays, id: \.self) { day in
                Section(day.formatted(date: .abbreviated, time: .omitted)) {
                    ForEach(filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }) { item in
                        Button { selection = item } label: {
                            TransactionRow(transaction: item.transaction)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(WalletTheme.background(colorScheme))
        .navigationTitle("Activity")
        .searchable(text: $search, prompt: "Search merchant or category")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { calendar = true } label: { Label("Calendar", systemImage: "calendar") }
                Button(action: onAdd) { Label("Add Expense", systemImage: "plus") }
            }
        }
        .navigationDestination(isPresented: $calendar) { TransactionCalendarView(onSave: onSave) }
        .sheet(item: $selection) { TransactionDetailView(storedTransaction: $0) }
    }
}
