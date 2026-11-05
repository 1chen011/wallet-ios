import Foundation

struct CaptureExtraction {
    let amount: String
    let merchant: String
    let currencyCode: String
    let date: Date?
    let warnings: [String]
}

/// Conservative, rule-based extraction. Never silently chooses between multiple plausible prices.
enum ExpenseExtractionService {
    static func extract(lines: [String]) -> CaptureExtraction {
        let text = lines.joined(separator: "\n")
        let upper = text.uppercased()
        var warnings: [String] = []

        let currency: String
        if upper.contains("USD") || upper.contains("US$") {
            currency = "USD"
        } else if upper.contains("CNY") || upper.contains("RMB") || text.contains("人民币") || text.contains("￥") {
            currency = "CNY"
        } else {
            currency = "CAD"
            if upper.contains("$") && !upper.contains("CAD") && !upper.contains("CA$") {
                warnings.append("Currency assumed CAD. Check it before saving.")
            }
        }

        // Strongest signal: an amount on a payment/total line, as distinct from balances,
        // rewards, tips, fees, and authorization references.
        let amountPattern = #"(?:CA\$|US\$|CAD\s*|USD\s*|CNY\s*|RMB\s*|[$￥¥])\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)|\b([0-9][0-9,]*\.[0-9]{2})\b"#
        let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive)
        var prioritized: [(value: String, priority: Int)] = []
        for line in lines {
            let ns = line as NSString
            let lower = line.lowercased()
            if ["balance", "available", "credit limit", "reward", "points", "cashback", "account balance", "余额", "积分"].contains(where: lower.contains) {
                continue
            }
            let priority = ["total", "paid", "payment", "purchase", "charged", "spent", "amount", "交易金额", "支付", "付款", "消费", "合计"].contains(where: lower.contains) ? 2 : 1
            for match in regex?.matches(in: line, range: NSRange(location: 0, length: ns.length)) ?? [] {
                let group = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
                guard group.location != NSNotFound else { continue }
                let raw = ns.substring(with: group).replacingOccurrences(of: ",", with: "")
                guard CaptureAmount.parse(raw) != nil else { continue }
                prioritized.append((raw, priority))
            }
        }
        let strongest = prioritized.map(\.priority).max() ?? 0
        let amounts = Array(Set(prioritized.filter { $0.priority == strongest }.map(\.value)))
        let amount: String
        if amounts.count == 1 {
            amount = amounts[0]
        } else {
            amount = ""
            warnings.append(amounts.isEmpty ? "Amount not recognized. Enter it manually." : "Multiple amounts detected. Check the screenshot and enter the charged amount.")
        }

        let merchantPatterns = [
            #"(?i)\b(?:merchant|store|paid to|purchase at|payment to)\s*[:：-]?\s*(.+)$"#,
            #"(?:商户|商家|收款方|付款给)\s*[:：-]?\s*(.+)$"#
        ]
        var merchant = ""
        for line in lines {
            for pattern in merchantPatterns {
                guard let regex = try? NSRegularExpression(pattern: pattern),
                      let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                      let range = Range(match.range(at: 1), in: line) else { continue }
                let candidate = String(line[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !candidate.isEmpty && candidate.count < 70 { merchant = candidate; break }
            }
            if !merchant.isEmpty { break }
        }
        if merchant.isEmpty { warnings.append("Merchant not confidently identified. Enter it if needed.") }

        var parsedDate: Date?
        // Only use explicitly recognized date strings; never use screenshot creation time as purchase date.
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            for line in lines {
                let ns = line as NSString
                let matches = detector.matches(in: line, range: NSRange(location: 0, length: ns.length))
                if let result = matches.first(where: { $0.date != nil && $0.date! <= Date() }) {
                    parsedDate = result.date
                    break
                }
            }
        }
        if parsedDate == nil { warnings.append("Date not detected; today's date is preselected. Please verify.") }
        return CaptureExtraction(amount: amount, merchant: merchant, currencyCode: currency, date: parsedDate, warnings: warnings)
    }
}
