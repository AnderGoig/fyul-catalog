public protocol ProductLoading: Sendable {
    func page(skip: Int, limit: Int) async throws -> ProductPage
    func product(id: Int) async throws -> Product
}

extension APIClient: ProductLoading {}
