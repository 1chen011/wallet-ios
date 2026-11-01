import Foundation
import SwiftData

/// A received refund linked to an existing completed expense.
/// Refunds are not ordinary income and do not create a second expense.
@Model
final class StoredRefund {
    @Attribute(.unique) var id: UUID
    var transactionId: UUID
    var amountInMinorUnits: Int64
    var currencyCode: String
    var date: Date
    var note: String?

    init(
        id: UUID = UUID(),
        transactionId: UUID,
        amountInMinorUnits: Int64,
        currencyCode: String,
        date: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.transactionId = transactionId
        self.amountInMinorUnits = amountInMinorUnits
        self.currencyCode = currencyCode
        self.date = date
        self.note = note
    }
}
