import Foundation
import SwiftData

/// An unconfirmed capture. Drafts are intentionally separate from transactions.
@Model
final class StoredDraft {
    @Attribute(.unique) var id: UUID
    var amountInMinorUnits: Int64?
    var currencyCode: String
    var merchant: String?
    var expenseDescription: String?
    var date: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        amountInMinorUnits: Int64? = nil,
        currencyCode: String = "CAD",
        merchant: String? = nil,
        expenseDescription: String? = nil,
        date: Date = .now,
        createdAt: Date = .now
    ) {
        self.id = id
        self.amountInMinorUnits = amountInMinorUnits
        self.currencyCode = currencyCode
        self.merchant = merchant
        self.expenseDescription = expenseDescription
        self.date = date
        self.createdAt = createdAt
    }

    var formattedAmount: String {
        guard let amountInMinorUnits else { return "Amount needed" }
        return (Decimal(amountInMinorUnits) / 100)
            .formatted(.currency(code: currencyCode))
    }
}

/// Shared validation for capture and review. Amounts stay in integer cents.
enum CaptureAmount {
    static func parse(_ value: String) -> Int64? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^[0-9]+(\.[0-9]{1,2})?$"#,
                               options: .regularExpression) != nil else { return nil }
        let parts = normalized.split(separator: ".", omittingEmptySubsequences: false)
        guard let whole = Int64(parts[0]) else { return nil }
        let fraction: Int64
        if parts.count == 2 {
            let digits = String(parts[1])
            guard let parsed = Int64(digits.count == 1 ? digits + "0" : digits) else { return nil }
            fraction = parsed
        } else { fraction = 0 }
        let (base, overflow) = whole.multipliedReportingOverflow(by: 100)
        guard !overflow else { return nil }
        let (total, additionOverflow) = base.addingReportingOverflow(fraction)
        return !additionOverflow && total > 0 ? total : nil
    }

    static func inputValue(_ amount: Int64?) -> String {
        guard let amount else { return "" }
        return "\(amount / 100).\(String(format: "%02d", amount % 100))"
    }
}
