import CatalogKit
import Testing

actor FakeProductLoader: ProductLoading {
    typealias PageResponse = @Sendable () async throws -> ProductPage
    typealias ProductResponse = @Sendable () async throws -> Product

    private var pageResponses: [PageResponse]
    private var productResponses: [ProductResponse]
    private(set) var requestedSkips: [Int] = []
    private(set) var requestedProductIDs: [Int] = []

    init(pages: [PageResponse] = [], products: [ProductResponse] = []) {
        pageResponses = pages
        productResponses = products
    }

    func page(skip: Int, limit: Int) async throws -> ProductPage {
        requestedSkips.append(skip)
        guard !pageResponses.isEmpty else {
            Issue.record("Unexpected page request at skip \(skip)")
            throw APIError.network
        }
        return try await pageResponses.removeFirst()()
    }

    func product(id: Int) async throws -> Product {
        requestedProductIDs.append(id)
        guard !productResponses.isEmpty else {
            Issue.record("Unexpected request for product \(id)")
            throw APIError.network
        }
        return try await productResponses.removeFirst()()
    }
}
