import CatalogKit
import SwiftUI

struct ProductDetailSections: View {
    let product: Product

    var body: some View {
        Section {
            LabeledContent("Minimum Order", value: product.minimumOrderQuantity, format: .number)
            LabeledContent("SKU") {
                Text(product.sku)
                    .textSelection(.enabled)
            }
            LabeledContent("Barcode") {
                Text(product.meta.barcode)
                    .textSelection(.enabled)
            }
            LabeledContent("Category", value: product.category.categoryTitle)
            if let brand = product.brand {
                LabeledContent("Brand", value: brand)
            }
        }

        Section("Description") {
            Text(product.description)
        }

        Section("Policies") {
            LabeledContent("Shipping", value: product.shippingInformation)
            LabeledContent("Warranty", value: product.warrantyInformation)
            LabeledContent("Returns", value: product.returnPolicy)
        }

        Section {
            ForEach(product.reviews.indices, id: \.self) { index in
                ReviewRow(review: product.reviews[index])
            }
        } header: {
            HStack {
                Text("Reviews")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                    Text(product.rating, format: .number.precision(.fractionLength(1)))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Average rating \(product.rating.formatted(.number.precision(.fractionLength(1))))"))
            }
        }
    }
}
