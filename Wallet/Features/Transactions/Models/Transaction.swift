
import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case expense
    case income
    case reimbursement
}

struct Transaction: Identifiable, Codable, Equatable {
    let id: UUID
    let type: TransactionType
    let amountInMinorUnits: Int64
    let currencyCode: String
    let categoryId: String
    let date: Date

    init(
        id: UUID = UUID(),
        type: TransactionType = .expense,
        amountInMinorUnits: Int64,
        currencyCode: String = "CAD",
        categoryId: String,
        date: Date = .now
    ) {
        self.id = id
        self.type = type
        self.amountInMinorUnits = amountInMinorUnits
        self.currencyCode = currencyCode
        self.categoryId = categoryId
        self.date = date
    }

    var formattedAmount: String {
        let amount = Decimal(amountInMinorUnits) / 100
        return amount.formatted(.currency(code: currencyCode))
    }
}

struct ExpenseCategory: Identifiable, Hashable {
    let id: String
    let name: String

    static let presets: [ExpenseCategory] = [
        .init(id: "food", name: "Food"),
        .init(id: "transportation", name: "Transportation"),
        .init(id: "shopping", name: "Shopping"),
        .init(id: "entertainment", name: "Entertainment"),
        .init(id: "housing", name: "Housing"),
        .init(id: "bills", name: "Bills"),
        .init(id: "other", name: "Other")
    ]

    static func name(for id: String) -> String {
        presets.first { $0.id == id }?.name ?? "Other"
    }
}
