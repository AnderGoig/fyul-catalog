public struct ProductPage: Decodable, Sendable, Equatable {
    public let products: [ProductSummary]
    public let total: Int
    public let skip: Int
    public let limit: Int

    public init(products: [ProductSummary], total: Int, skip: Int, limit: Int) {
        self.products = products
        self.total = total
        self.skip = skip
        self.limit = limit
    }
}
