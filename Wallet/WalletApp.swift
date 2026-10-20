
import SwiftUI
import SwiftData

@main
struct WalletApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: StoredTransaction.self)
    }
}
