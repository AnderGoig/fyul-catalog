import CatalogKit
import SwiftUI

struct ProductListView: View {
    let viewModel: ProductListViewModel
    let loader: any ProductLoading

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading products")
            case .empty:
                ContentUnavailableView {
                    Label("No Products", systemImage: "shippingbox")
                } description: {
                    Text("Your catalog has no products yet.")
                } actions: {
                    Button("Reload", action: retry)
                }
            case .failed(let error):
                LoadFailedView(error: error, retry: retry)
            case .loaded(let content):
                List {
                    if content.refreshError != nil {
                        RefreshFailedRow(retry: refresh)
                    }
                    ForEach(content.products) { product in
                        NavigationLink(value: product) {
                            ProductRow(product: product)
                        }
                    }
                    NextPageRow(nextPage: content.nextPage, total: content.total, loadNextPage: loadNextPage)
                }
                .listStyle(.plain)
                .refreshable { await viewModel.refresh() }
            }
        }
        .navigationTitle("Products")
        .navigationDestination(for: ProductSummary.self) { summary in
            ProductDetailView(summary: summary, loader: loader)
        }
        .task { await viewModel.loadIfNeeded() }
    }

    private func retry() {
        Task { await viewModel.retry() }
    }

    private func refresh() {
        Task { await viewModel.refresh() }
    }

    private func loadNextPage() {
        viewModel.loadNextPage()
    }
}
