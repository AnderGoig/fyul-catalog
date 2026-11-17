import CatalogKit
import SwiftUI

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel

    init(summary: ProductSummary, loader: any ProductLoading) {
        _viewModel = State(initialValue: ProductDetailViewModel(summary: summary, loader: loader))
    }

    var body: some View {
        List {
            header
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case .failed(.notFound):
                ContentUnavailableView(
                    "No Longer Available",
                    systemImage: "shippingbox",
                    description: Text("This product was removed from the catalog.")
                )
            case .failed:
                VStack(spacing: 8) {
                    Text("Couldn't load the details.")
                    Button("Retry") {
                        Task { await viewModel.retry() }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
            case .loaded(let product):
                ProductDetailSections(product: product)
            }
        }
        .navigationTitle(viewModel.summary.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private var header: some View {
        let summary = viewModel.summary
        let product = viewModel.state.product
        return Section {
            ProductImage(url: product?.images.first ?? summary.thumbnail, fallback: summary.thumbnail)
                .frame(height: 280)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(summary.title))
                .accessibilityAddTraits(.isImage)

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

private struct ProductDetailSections: View {
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
            ForEach(Array(product.reviews.enumerated()), id: \.offset) { _, review in
                ReviewRow(review: review)
            }
        } header: {
            HStack {
                Text("Reviews")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .accessibilityHidden(true)
                    Text(product.rating, format: .number.precision(.fractionLength(1)))
                }
            }
        }
    }
}

private struct ReviewRow: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(review.reviewerName)
                    .font(.headline)
                Spacer()
                Text(review.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(review.rating) out of 5")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(review.comment)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension ProductDetailViewModel.State {
    var product: Product? {
        guard case .loaded(let product) = self else { return nil }
        return product
    }
}
