import CatalogKit
import Observation

@MainActor
@Observable
final class ProductListViewModel {
    enum State: Equatable {
        case loading
        case loaded(Content)
        case empty
        case failed(APIError)
    }

    struct Content: Equatable {
        var products: [ProductSummary]
        var total: Int
        var nextSkip: Int
        var nextPage: NextPage
        var refreshError: APIError?
    }

    enum NextPage: Equatable {
        case idle
        case loading
        case failed(APIError)
        case complete

        init(nextSkip: Int, total: Int) {
            self = nextSkip < total ? .idle : .complete
        }
    }

    private static let pageSize = 30

    private(set) var state: State = .loading
    private let loader: any ProductLoading
    private var pageTask: Task<Void, Never>?

    init(loader: any ProductLoading) {
        self.loader = loader
    }

    func loadIfNeeded() async {
        guard state == .loading else { return }
        await loadFirstPage()
    }

    func retry() async {
        state = .loading
        await loadFirstPage()
    }

    func refresh() async {
        cancelPageInFlight()
        do {
            let page = try await loader.page(skip: 0, limit: Self.pageSize)
            state = Self.state(forFirstPage: page)
        } catch is CancellationError {
        } catch {
            guard case .loaded(var content) = state else { return }
            content.refreshError = error as? APIError ?? .network
            state = .loaded(content)
        }
    }

    @discardableResult
    func loadNextPage() -> Task<Void, Never>? {
        guard case .loaded(var content) = state else { return nil }
        switch content.nextPage {
        case .idle, .failed: break
        case .loading, .complete: return nil
        }
        content.nextPage = .loading
        state = .loaded(content)
        let skip = content.nextSkip
        let task = Task {
            do {
                let page = try await loader.page(skip: skip, limit: Self.pageSize)
                guard !Task.isCancelled, case .loaded(var content) = state else { return }
                let loadedIDs = Set(content.products.map(\.id))
                content.products += page.products.filter { !loadedIDs.contains($0.id) }
                content.nextSkip = page.skip + page.products.count
                content.nextPage = NextPage(nextSkip: content.nextSkip, total: page.total)
                state = .loaded(content)
            } catch {
                guard !Task.isCancelled, case .loaded(var content) = state else { return }
                content.nextPage = error is CancellationError ? .idle : .failed(error as? APIError ?? .network)
                state = .loaded(content)
            }
        }
        pageTask = task
        return task
    }

    private func cancelPageInFlight() {
        pageTask?.cancel()
        pageTask = nil
        guard case .loaded(var content) = state, content.nextPage == .loading else { return }
        content.nextPage = .idle
        state = .loaded(content)
    }

    private func loadFirstPage() async {
        do {
            let page = try await loader.page(skip: 0, limit: Self.pageSize)
            state = Self.state(forFirstPage: page)
        } catch is CancellationError {
        } catch {
            state = .failed(error as? APIError ?? .network)
        }
    }

    private static func state(forFirstPage page: ProductPage) -> State {
        guard !page.products.isEmpty else { return .empty }
        let nextSkip = page.skip + page.products.count
        return .loaded(Content(
            products: page.products,
            total: page.total,
            nextSkip: nextSkip,
            nextPage: NextPage(nextSkip: nextSkip, total: page.total)
        ))
    }
}
