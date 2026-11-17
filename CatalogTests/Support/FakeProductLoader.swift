import CatalogKit
import Foundation

actor FakeProductLoader: ProductLoading {
    typealias PageResponse = @Sendable () async throws -> ProductPage

    private var pageResponses: [PageResponse]
    private(set) var requestedSkips: [Int] = []

    init(pages: [PageResponse]) {
        pageResponses = pages
    }

    func page(skip: Int, limit: Int) async throws -> ProductPage {
        requestedSkips.append(skip)
        guard !pageResponses.isEmpty else { throw APIError.network }
        return try await pageResponses.removeFirst()()
    }
}

actor Gate {
    private var isOpen = false
    private var hasArrival = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var arrivalWaiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        hasArrival = true
        arrivalWaiters.forEach { $0.resume() }
        arrivalWaiters.removeAll()
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func waitForArrival() async {
        guard !hasArrival else { return }
        await withCheckedContinuation { arrivalWaiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }
}

extension ProductPage {
    static func stub(ids: ClosedRange<Int>, skip: Int, total: Int) -> ProductPage {
        ProductPage(products: ids.map(ProductSummary.stub), total: total, skip: skip, limit: 30)
    }
}

extension ProductSummary {
    static func stub(id: Int) -> ProductSummary {
        ProductSummary(
            id: id,
            title: "Product \(id)",
            price: 9.99,
            stock: 5,
            availabilityStatus: .inStock,
            category: "beauty",
            thumbnail: URL(filePath: "/thumbnails/\(id).webp")
        )
    }
}
