public protocol ProductLoading: Sendable {
    func page(skip: Int, limit: Int) async throws -> ProductPage
}

extension APIClient: ProductLoading {}
