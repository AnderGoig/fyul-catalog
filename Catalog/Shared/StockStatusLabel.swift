import CatalogKit
import SwiftUI

struct StockStatusLabel: View {
    let status: AvailabilityStatus
    let stock: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .accessibilityHidden(true)
            Text("\(title) · \(stock)")
        }
        .foregroundStyle(tint)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(title), quantity \(stock)"))
    }

    private var title: String {
        switch status {
        case .inStock: String(localized: "In Stock")
        case .lowStock: String(localized: "Low Stock")
        case .outOfStock: String(localized: "Out of Stock")
        case .other(let value): value
        }
    }

    private var symbol: String {
        switch status {
        case .inStock: "checkmark.circle.fill"
        case .lowStock: "exclamationmark.triangle.fill"
        case .outOfStock: "xmark.circle.fill"
        case .other: "questionmark.circle"
        }
    }

    private var tint: Color {
        switch status {
        case .inStock: .green
        case .lowStock: .orange
        case .outOfStock: .red
        case .other: .secondary
        }
    }
}
