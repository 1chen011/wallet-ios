
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
    var paymentStatusRawValue: String = "completed"

    var paymentStatus: PaymentStatus {
        get { PaymentStatus(rawValue: paymentStatusRawValue) ?? .completed }
        set { paymentStatusRawValue = newValue.rawValue }
    }

    init(transaction: Transaction) {
        self.id = transaction.id
        self.typeRawValue = transaction.type.rawValue
        self.amountInMinorUnits = transaction.amountInMinorUnits
        self.currencyCode = transaction.currencyCode
        self.categoryId = transaction.categoryId
        self.date = transaction.date
        self.merchant = transaction.merchant
        self.expenseDescription = transaction.expenseDescription
        self.paymentStatusRawValue = transaction.paymentStatus.rawValue
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
            expenseDescription: expenseDescription,
            paymentStatus: paymentStatus
        )
    }
}
