
import AppIntents
import Foundation

struct QuickAddLaunchIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Add Expense"

    static let description = IntentDescription(
        "Open Wallet to quickly record an expense."
    )

    static let openAppWhenRun = true

    static let requestKey = "wallet.quickAdd.openRequested"

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(
            true,
            forKey: Self.requestKey
        )

        NotificationCenter.default.post(
            name: .walletQuickAddRequested,
            object: nil
        )

        return .result()
    }
}

extension Notification.Name {
    static let walletQuickAddRequested = Notification.Name(
        "wallet.quickAdd.requested"
    )
}
