public struct ProductPage: Decodable, Sendable, Equatable {
    public let products: [ProductSummary]
    public let total: Int
    public let skip: Int
    public let limit: Int
}
