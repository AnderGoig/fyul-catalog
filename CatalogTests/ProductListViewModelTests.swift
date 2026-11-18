import CatalogKit
import Testing
@testable import Catalog

@MainActor
@Suite("Product list view model")
struct ProductListViewModelTests {
    @Test func firstLoadShowsTheFirstPage() async {
        let loader = FakeProductLoader(pages: [{ .stub(ids: 1...30, skip: 0, total: 194) }])
        let viewModel = ProductListViewModel(loader: loader)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .loaded(.init(
            products: (1...30).map(ProductSummary.stub),
            total: 194,
            nextSkip: 30,
            nextPage: .idle
        )))
    }

    @Test func emptyCatalogShowsEmpty() async {
        let loader = FakeProductLoader(pages: [{ ProductPage(products: [], total: 0, skip: 0, limit: 30) }])
        let viewModel = ProductListViewModel(loader: loader)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .empty)
    }

    @Test func firstLoadFailureShowsFailed() async {
        let loader = FakeProductLoader(pages: [{ throw APIError.network }])
        let viewModel = ProductListViewModel(loader: loader)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .failed(.network))
    }

    @Test func cancelledFirstLoadIsNotAnError() async {
        let loader = FakeProductLoader(pages: [{ throw CancellationError() }])
        let viewModel = ProductListViewModel(loader: loader)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .loading)
    }

    @Test func retryAfterFailureLoadsTheFirstPage() async {
        let loader = FakeProductLoader(pages: [
            { throw APIError.server(status: 503) },
            { .stub(ids: 1...30, skip: 0, total: 194) },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()

        await viewModel.retry()

        #expect(viewModel.state.products.map(\.id) == Array(1...30))
    }

    @Test func loadIfNeededDoesNotReloadOnceLoaded() async {
        let loader = FakeProductLoader(pages: [{ .stub(ids: 1...30, skip: 0, total: 194) }])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()

        await viewModel.loadIfNeeded()

        #expect(await loader.requestedSkips == [0])
    }

    @Test func nextPageAppendsAfterTheLoadedRows() async {
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { .stub(ids: 31...60, skip: 30, total: 194) },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()

        await viewModel.loadNextPage()?.value

        #expect(viewModel.state.products.map(\.id) == Array(1...60))
        #expect(await loader.requestedSkips == [0, 30])
    }

    @Test func nextPageIsRequestedOnceWhileItLoads() async {
        let gate = Gate()
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { await gate.wait(); return .stub(ids: 31...60, skip: 30, total: 194) },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()

        let first = viewModel.loadNextPage()
        let second = viewModel.loadNextPage()
        await gate.open()
        await first?.value

        #expect(second == nil)
        #expect(await loader.requestedSkips == [0, 30])
    }

    @Test func lastPageCompletesTheList() async {
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 40) },
            { .stub(ids: 31...40, skip: 30, total: 40) },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()

        await viewModel.loadNextPage()?.value

        #expect(viewModel.state.nextPage == .complete)
        #expect(viewModel.loadNextPage() == nil)
    }

    @Test func failedPageKeepsTheLoadedRows() async {
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { throw APIError.network },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()

        await viewModel.loadNextPage()?.value

        #expect(viewModel.state.products.map(\.id) == Array(1...30))
        #expect(viewModel.state.nextPage == .failed(.network))
    }

    @Test func failedPageCanBeRetried() async {
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { throw APIError.network },
            { .stub(ids: 31...60, skip: 30, total: 194) },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()
        await viewModel.loadNextPage()?.value

        await viewModel.loadNextPage()?.value

        #expect(viewModel.state.products.map(\.id) == Array(1...60))
    }

    @Test func productsAlreadyLoadedAreNotAddedTwice() async {
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { .stub(ids: 29...58, skip: 30, total: 194) },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()

        await viewModel.loadNextPage()?.value

        #expect(viewModel.state.products.map(\.id) == Array(1...58))
    }

    @Test func refreshReplacesTheLoadedPages() async {
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { .stub(ids: 31...60, skip: 30, total: 194) },
            { .stub(ids: 101...130, skip: 0, total: 194) },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()
        await viewModel.loadNextPage()?.value

        await viewModel.refresh()

        #expect(viewModel.state.products.map(\.id) == Array(101...130))
        #expect(await loader.requestedSkips == [0, 30, 0])
    }

    @Test func failedRefreshKeepsTheRowsAndReportsIt() async {
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { throw APIError.server(status: 503) },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()

        await viewModel.refresh()

        #expect(viewModel.state.products.map(\.id) == Array(1...30))
        #expect(viewModel.state.refreshError == .server(status: 503))
    }

    @Test func cancelledRefreshIsNotAnError() async {
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { throw CancellationError() },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()

        await viewModel.refresh()

        #expect(viewModel.state.products.map(\.id) == Array(1...30))
        #expect(viewModel.state.refreshError == nil)
    }

    @Test func refreshDropsThePageInFlight() async {
        let gate = Gate()
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { await gate.wait(); return .stub(ids: 31...60, skip: 30, total: 194) },
            { .stub(ids: 101...130, skip: 0, total: 194) },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()
        let pageInFlight = viewModel.loadNextPage()
        await gate.waitForArrival()

        await viewModel.refresh()
        await gate.open()
        await pageInFlight?.value

        #expect(viewModel.state.products.map(\.id) == Array(101...130))
        #expect(viewModel.state.nextPage == .idle)
    }

    @Test func nextPageDoesNotStartWhileARefreshRuns() async {
        let gate = Gate()
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { await gate.wait(); return .stub(ids: 101...130, skip: 0, total: 194) },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()
        let refresh = Task { await viewModel.refresh() }
        await gate.waitForArrival()

        let page = viewModel.loadNextPage()
        await gate.open()
        await refresh.value

        #expect(page == nil)
        #expect(await loader.requestedSkips == [0, 0])
    }

    @Test func cancelledPageIsNotAnError() async {
        let loader = FakeProductLoader(pages: [
            { .stub(ids: 1...30, skip: 0, total: 194) },
            { throw CancellationError() },
        ])
        let viewModel = ProductListViewModel(loader: loader)
        await viewModel.loadIfNeeded()

        await viewModel.loadNextPage()?.value

        #expect(viewModel.state.nextPage == .idle)
    }
}

extension ProductListViewModel.State {
    var products: [ProductSummary] {
        guard case .loaded(let content) = self else { return [] }
        return content.products
    }

    var nextPage: ProductListViewModel.NextPage? {
        guard case .loaded(let content) = self else { return nil }
        return content.nextPage
    }

    var refreshError: APIError? {
        guard case .loaded(let content) = self else { return nil }
        return content.refreshError
    }
}
