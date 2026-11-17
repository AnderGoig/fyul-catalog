import CatalogKit
import Testing
@testable import Catalog

@MainActor
@Suite("Product detail view model")
struct ProductDetailViewModelTests {
    @Test func loadShowsTheFullProduct() async throws {
        let product = try Product.stub(id: 9, stock: 2)
        let loader = FakeProductLoader(products: [{ product }])
        let viewModel = ProductDetailViewModel(summary: .stub(id: 9), loader: loader)

        await viewModel.load()

        #expect(viewModel.state == .loaded(product))
        #expect(await loader.requestedProductIDs == [9])
    }

    @Test func failureShowsFailedWithTheError() async {
        let loader = FakeProductLoader(products: [{ throw APIError.notFound }])
        let viewModel = ProductDetailViewModel(summary: .stub(id: 9), loader: loader)

        await viewModel.load()

        #expect(viewModel.state == .failed(.notFound))
    }

    @Test func cancelledLoadIsNotAnError() async {
        let loader = FakeProductLoader(products: [{ throw CancellationError() }])
        let viewModel = ProductDetailViewModel(summary: .stub(id: 9), loader: loader)

        await viewModel.load()

        #expect(viewModel.state == .loading)
    }

    @Test func retryAfterFailureLoadsTheProduct() async throws {
        let product = try Product.stub(id: 9)
        let loader = FakeProductLoader(products: [{ throw APIError.network }, { product }])
        let viewModel = ProductDetailViewModel(summary: .stub(id: 9), loader: loader)
        await viewModel.load()

        await viewModel.retry()

        #expect(viewModel.state == .loaded(product))
    }
}
