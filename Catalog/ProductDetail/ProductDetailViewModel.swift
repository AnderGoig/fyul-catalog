import CatalogKit
import Observation

@MainActor
@Observable
final class ProductDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded(Product)
        case failed(APIError)
    }

    let summary: ProductSummary
    private(set) var state: State = .loading
    private let loader: any ProductLoading

    init(summary: ProductSummary, loader: any ProductLoading) {
        self.summary = summary
        self.loader = loader
    }

    func retry() async {
        state = .loading
        await load()
    }

    func load() async {
        do {
            state = .loaded(try await loader.product(id: summary.id))
        } catch is CancellationError {
        } catch {
            state = .failed(error as? APIError ?? .network)
        }
    }
}

extension ProductDetailViewModel.State {
    var product: Product? {
        guard case .loaded(let product) = self else { return nil }
        return product
    }
}
