import SwiftUI

struct NextPageRow: View {
    let nextPage: ProductListViewModel.NextPage
    let total: Int
    let loadNextPage: () -> Void

    var body: some View {
        Group {
            switch nextPage {
            case .idle:
                ProgressView()
                    .accessibilityLabel(Text("Loading more products"))
                    .onAppear(perform: loadNextPage)
            case .loading:
                ProgressView()
                    .accessibilityLabel(Text("Loading more products"))
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
