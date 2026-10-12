import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Welcome to Wallet")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Track your spending. Plan your future.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    print("Add Expense tapped")
                } label: {
                    Label("Add Expense", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Wallet")
        }
    }
}

#Preview {
    ContentView()
}
