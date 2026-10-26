
import Foundation
import SwiftData

@Model
final class StoredTransaction {
    @Attribute(.unique) var id: UUID

    var typeRawValue: String
    var amountInMinorUnits: Int64
    var currencyCode: String
    var categoryId: String
    var date: Date
    var merchant: String? = nil
    var expenseDescription: String? = nil

    init(transaction: Transaction) {
        self.id = transaction.id
        self.typeRawValue = transaction.type.rawValue
        self.amountInMinorUnits = transaction.amountInMinorUnits
        self.currencyCode = transaction.currencyCode
        self.categoryId = transaction.categoryId
        self.date = transaction.date
        self.merchant = transaction.merchant
        self.expenseDescription = transaction.expenseDescription
    }

    var transaction: Transaction {
        Transaction(
            id: id,
            type: TransactionType(rawValue: typeRawValue) ?? .expense,
            amountInMinorUnits: amountInMinorUnits,
            currencyCode: currencyCode,
            categoryId: categoryId,
            date: date,
            merchant: merchant,
            expenseDescription: expenseDescription
        )
    }
}
