import SwiftUI
import SwiftData

struct TransactionCalendarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \StoredTransaction.date, order: .reverse) private var transactions: [StoredTransaction]
    @State private var selectedDate = Date()
    @State private var displayedMonth = Calendar.current.startOfMonth(for: .now)
    @State private var showingAdd = false
    @State private var selectedTransaction: StoredTransaction?
    let onSave: (Transaction) -> Void

    private var calendar: Calendar { .current }
    private var dayTransactions: [StoredTransaction] {
        transactions.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)
                    Spacer()
                    Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
                        .disabled(!canMoveForward)
                }
                .foregroundStyle(WalletTheme.primaryText(colorScheme))
                monthGrid
                HStack {
                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                    Spacer()
                    Button { showingAdd = true } label: {
                        Label("Add Expense", systemImage: "plus.circle.fill")
                    }
                    .disabled(selectedDate > Date())
                }
                .foregroundStyle(WalletTheme.primaryText(colorScheme))
                if dayTransactions.isEmpty {
                    ContentUnavailableView("No expenses on this day", systemImage: "calendar")
                } else {
                    ForEach(dayTransactions) { stored in
                        Button { selectedTransaction = stored } label: {
                            TransactionRow(transaction: stored.transaction)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(WalletTheme.horizontalPadding)
        }
        .background(WalletTheme.background(colorScheme))
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAdd) {
            AddExpenseView(initialDate: selectedDate, onSave: onSave)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(storedTransaction: transaction)
        }
    }

    private var canMoveForward: Bool {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return false }
        return next <= Date()
    }

    private func changeMonth(_ amount: Int) {
        guard let next = calendar.date(byAdding: .month, value: amount, to: displayedMonth),
              next <= Date() else { return }
        displayedMonth = next
        selectedDate = next
    }

    private var monthGrid: some View {
        let weekdayOffset = (calendar.component(.weekday, from: displayedMonth) - calendar.firstWeekday + 7) % 7
        let numberOfDays = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
        return VStack(spacing: 10) {
            HStack {
                ForEach(0..<7, id: \.self) { offset in
                    let weekday = (calendar.firstWeekday - 1 + offset) % 7
                    Text(calendar.veryShortStandaloneWeekdaySymbols[weekday])
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(WalletTheme.secondaryText(colorScheme))
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<(weekdayOffset + numberOfDays), id: \.self) { index in
                    if index < weekdayOffset {
                        Color.clear.frame(height: 45)
                    } else {
                        dayButton(index - weekdayOffset + 1)
                    }
                }
            }
        }
        .padding(12)
        .background(WalletTheme.surface(colorScheme), in: RoundedRectangle(cornerRadius: WalletTheme.cornerRadius))
    }

    private func dayButton(_ day: Int) -> some View {
        let date = calendar.date(byAdding: .day, value: day - 1, to: displayedMonth) ?? displayedMonth
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasEntries = transactions.contains { calendar.isDate($0.date, inSameDayAs: date) }
        let future = calendar.startOfDay(for: date) > calendar.startOfDay(for: .now)
        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 4) {
                Text("\(day)").font(.subheadline.weight(selected ? .bold : .regular))
                Circle().fill(hasEntries ? WalletTheme.gold : .clear).frame(width: 5, height: 5)
            }
            .foregroundStyle(selected ? WalletTheme.navy : WalletTheme.primaryText(colorScheme))
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(selected ? WalletTheme.gold.opacity(0.45) : .clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .disabled(future)
        .buttonStyle(.plain)
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
