import AppIntents
import SwiftUI
import WidgetKit

struct WalletQuickAddControlControl: ControlWidget {
    static let kind = "com.yichen.Wallet.quickAdd"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: QuickAddLaunchIntent()) {
                Label("Quick Add", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Wallet Quick Add")
        .description("Quickly record an expense in Wallet.")
    }
}
