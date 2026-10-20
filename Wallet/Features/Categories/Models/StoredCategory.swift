import Foundation
import SwiftData
import SwiftUI

@Model
final class StoredCategory {
    @Attribute(.unique) var id: String
    var name: String
    var iconName: String
    var colorHex: Int
    var isArchived: Bool
    var sortOrder: Int

    init(id: String = UUID().uuidString, name: String, iconName: String = "tag.fill", colorHex: Int = 0xE8E1F1, isArchived: Bool = false, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isArchived = isArchived
        self.sortOrder = sortOrder
    }

    var color: Color {
        Color(.sRGB, red: Double((colorHex >> 16) & 255) / 255, green: Double((colorHex >> 8) & 255) / 255, blue: Double(colorHex & 255) / 255, opacity: 1)
    }
}

// Kept separate from StoredTransaction so existing transactions/schema remain unchanged.
enum CategoryCatalog {
    static let starterIDs = ["food", "shopping", "transportation", "other"]
    static let templates: [(id: String, name: String, icon: String, color: Int)] = [
        ("food", "Food & Drinks", "fork.knife", 0xE8D4C9),
        ("drinks", "Drinks", "cup.and.saucer.fill", 0xE8E1F1),
        ("shopping", "Shopping", "bag.fill", 0xDCE9DF),
        ("transportation", "Transportation", "car.fill", 0xDDE4F2),
        ("other", "Other", "square.grid.2x2.fill", 0xE5E5EB),
        ("housing", "Housing", "house.fill", 0xE8DED1),
        ("bills", "Bills", "doc.text.fill", 0xE5DFEA),
        ("shipping", "Shipping", "shippingbox.fill", 0xDCE7E4),
        ("entertainment", "Entertainment", "ticket.fill", 0xF0D9DC),
        ("subscriptions", "Subscriptions", "repeat", 0xE1DCF0)
    ]

    static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    static func availableTemplates(excluding categories: [StoredCategory]) -> [(id: String, name: String, icon: String, color: Int)] {
        templates.filter { template in
            !categories.contains { $0.id == template.id || normalized($0.name) == normalized(template.name) }
        }
    }

    // Seed exactly once per installation. Preserve all IDs used by earlier releases.
    static func seedIfNeeded(context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<StoredCategory>())
        guard existing.isEmpty else { return }
        let transactions = try context.fetch(FetchDescriptor<StoredTransaction>())
        let referenced = Set(transactions.map(\.categoryId))
        let ids = Set(starterIDs).union(referenced)
        for (index, template) in templates.enumerated() where ids.contains(template.id) {
            // Historical 'food' transactions keep their ID; the user can rename it later.
            let name = template.id == "food" && referenced.contains("drinks") ? "Food" : template.name
            context.insert(StoredCategory(id: template.id, name: name, iconName: template.icon, colorHex: template.color, sortOrder: index))
        }
        for id in referenced where !templates.contains(where: { $0.id == id }) {
            context.insert(StoredCategory(id: id, name: id, sortOrder: 100))
        }
        try context.save()
    }
}
