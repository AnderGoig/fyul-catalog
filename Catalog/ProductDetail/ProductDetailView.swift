import CatalogKit
import SwiftUI

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel

    init(summary: ProductSummary, loader: any ProductLoading) {
        _viewModel = State(initialValue: ProductDetailViewModel(summary: summary, loader: loader))
    }

    var body: some View {
        List {
            ProductDetailHeader(summary: viewModel.summary, product: viewModel.state.product)
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .accessibilityLabel(Text("Loading details"))
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
                    Button("Retry", action: retry)
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

    private func retry() {
        Task { await viewModel.retry() }
    }
}
