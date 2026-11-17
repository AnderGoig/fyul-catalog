import CatalogKit
import SwiftUI

struct ProductListView: View {
    let viewModel: ProductListViewModel

    var body: some View {
        content
            .navigationTitle("Products")
            .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView(
                "No Products",
                systemImage: "shippingbox",
                description: Text("Your catalog has no products yet.")
            )
        case .failed(let error):
            LoadFailedView(error: error) {
                Task { await viewModel.retry() }
            }
        case .loaded(let content):
            List {
                if content.refreshError != nil {
                    RefreshFailedRow {
                        Task { await viewModel.refresh() }
                    }
                }
                ForEach(content.products) { product in
                    ProductRow(product: product)
                }
                NextPageRow(nextPage: content.nextPage, total: content.total) {
                    viewModel.loadNextPage()
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.refresh() }
        }
    }
}

private struct LoadFailedView: View {
    let error: APIError
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            if error == .network {
                Label("Can't Reach the Catalog", systemImage: "wifi.slash")
            } else {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            }
        } description: {
            if error == .network {
                Text("Check your connection and try again.")
            } else {
                Text("Try again in a moment.")
            }
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct RefreshFailedRow: View {
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Couldn't refresh. Showing earlier results.", systemImage: "exclamationmark.arrow.circlepath")
            Button("Retry", action: retry)
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

private struct NextPageRow: View {
    let nextPage: ProductListViewModel.NextPage
    let total: Int
    let loadNextPage: () -> Void

    var body: some View {
        Group {
            switch nextPage {
            case .idle:
                ProgressView()
                    .onAppear(perform: loadNextPage)
            case .loading:
                ProgressView()
            case .failed:
                VStack(spacing: 8) {
                    Text("Couldn't load more products.")
                    Button("Retry", action: loadNextPage)
                        .buttonStyle(.bordered)
                }
            case .complete:
                Text("\(total) products")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
    }
}
