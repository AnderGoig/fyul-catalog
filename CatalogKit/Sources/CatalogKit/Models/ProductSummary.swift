import Foundation

public struct ProductSummary: Decodable, Sendable, Hashable, Identifiable {
    public let id: Int
    public let title: String
    public let price: Double
    public let stock: Int
    public let availabilityStatus: AvailabilityStatus
    public let category: String
    public let thumbnail: URL

    static let selectedFields = "title,price,stock,availabilityStatus,category,thumbnail"
}
