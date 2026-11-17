import CatalogKit
import Foundation

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
        guard !pageResponses.isEmpty else { throw APIError.network }
        return try await pageResponses.removeFirst()()
    }

    func product(id: Int) async throws -> Product {
        requestedProductIDs.append(id)
        guard !productResponses.isEmpty else { throw APIError.network }
        return try await productResponses.removeFirst()()
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

extension Product {
    static func stub(id: Int, stock: Int = 3) throws -> Product {
        let json: [String: Any] = [
            "id": id,
            "title": "Product \(id)",
            "description": "A product.",
            "sku": "SKU-\(id)",
            "meta": ["barcode": "000\(id)"],
            "category": "beauty",
            "price": 9.99,
            "discountPercentage": 10.5,
            "stock": stock,
            "availabilityStatus": "Low Stock",
            "minimumOrderQuantity": 5,
            "shippingInformation": "Ships in 1 week",
            "warrantyInformation": "No warranty",
            "returnPolicy": "No return policy",
            "images": ["https://cdn.example/\(id)/1.webp"],
            "rating": 4.5,
            "reviews": [],
        ]
        return try JSONDecoder().decode(Product.self, from: JSONSerialization.data(withJSONObject: json))
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
