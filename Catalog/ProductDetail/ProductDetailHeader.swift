import CatalogKit
import SwiftUI

struct ProductDetailHeader: View {
    let summary: ProductSummary
    let product: Product?

    var body: some View {
        Section {
            ProductImage(url: product?.images.first ?? summary.thumbnail, fallback: summary.thumbnail)
                .frame(height: 280)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(summary.title)
                    .font(.title2.bold())
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(product?.price ?? summary.price, format: .catalogPrice)
                        .font(.title3)
                    if let discount = product?.discountPercentage, discount > 0 {
                        Text("\((discount / 100).formatted(.percent.precision(.fractionLength(0...2)))) off")
                            .foregroundStyle(.secondary)
                    }
                }
                StockStatusLabel(
                    status: product?.availabilityStatus ?? summary.availabilityStatus,
                    stock: product?.stock ?? summary.stock
                )
            }
            .accessibilityElement(children: .combine)
        }
    }
}
