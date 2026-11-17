import CatalogKit
import SwiftUI

struct ProductRow: View {
    let product: ProductSummary

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var thumbnailSide = 64

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))

        layout {
            ProductImage(url: product.thumbnail)
                .frame(width: thumbnailSide, height: thumbnailSide)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.headline)
                Text(product.price, format: .catalogPrice)
                StockStatusLabel(status: product.availabilityStatus, stock: product.stock)
                    .font(.subheadline)
                Text(product.category.replacing("-", with: " ").localizedCapitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
