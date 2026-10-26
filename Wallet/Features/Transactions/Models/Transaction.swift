
import Foundation
import SwiftUI

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
    let merchant: String?
    let expenseDescription: String?

    init(
        id: UUID = UUID(),
        type: TransactionType = .expense,
        amountInMinorUnits: Int64,
        currencyCode: String = "CAD",
        categoryId: String,
        date: Date = .now,
        merchant: String? = nil,
        expenseDescription: String? = nil
    ) {
        self.id = id
        self.type = type
        self.amountInMinorUnits = amountInMinorUnits
        self.currencyCode = currencyCode
        self.categoryId = categoryId
        self.date = date
        self.merchant = merchant
        self.expenseDescription = expenseDescription
    }

    var formattedAmount: String {
        let amount = Decimal(amountInMinorUnits) / 100
        return amount.formatted(.currency(code: currencyCode))
    }
}

struct ExpenseCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let colorHex: UInt32

    var color: Color {
        Color(
            .sRGB,
            red: Double((colorHex >> 16) & 0xFF) / 255,
            green: Double((colorHex >> 8) & 0xFF) / 255,
            blue: Double(colorHex & 0xFF) / 255,
            opacity: 1
        )
    }

    static let presets: [ExpenseCategory] = [
        .init(
            id: "food",
            name: "Food",
            iconName: "fork.knife",
            colorHex: 0xE8D4C9
        ),
        .init(
            id: "drinks",
            name: "Drinks",
            iconName: "cup.and.saucer.fill",
            colorHex: 0xE8E1F1
        ),
        .init(
            id: "shopping",
            name: "Shopping",
            iconName: "bag.fill",
            colorHex: 0xDCE9DF
        ),
        .init(
            id: "transportation",
            name: "Transportation",
            iconName: "car.fill",
            colorHex: 0xDDE4F2
        ),
        .init(
            id: "housing",
            name: "Housing",
            iconName: "house.fill",
            colorHex: 0xE8DED1
        ),
        .init(
            id: "bills",
            name: "Bills",
            iconName: "doc.text.fill",
            colorHex: 0xE5DFEA
        ),
        .init(
            id: "entertainment",
            name: "Entertainment",
            iconName: "ticket.fill",
            colorHex: 0xF0D9DC
        ),
        .init(
            id: "shipping",
            name: "Shipping",
            iconName: "shippingbox.fill",
            colorHex: 0xDCE7E4
        ),
        .init(
            id: "other",
            name: "Other",
            iconName: "square.grid.2x2.fill",
            colorHex: 0xE5E5EB
        )
    ]

    static let quickCategoryIds = [
        "food",
        "drinks",
        "shopping",
        "transportation"
    ]

    static var quickCategories: [ExpenseCategory] {
        quickCategoryIds.compactMap { id in
            presets.first { $0.id == id }
        }
    }

    static func category(for id: String) -> ExpenseCategory? {
        presets.first { $0.id == id }
    }

    static func name(for id: String) -> String {
        category(for: id)?.name ?? "Other"
    }
}
