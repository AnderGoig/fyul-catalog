import Foundation

public struct Product: Decodable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let title: String
    public let description: String
    public let brand: String?
    public let sku: String
    public let meta: Meta
    public let category: String
    public let price: Double
    public let discountPercentage: Double
    public let stock: Int
    public let availabilityStatus: AvailabilityStatus
    public let minimumOrderQuantity: Int
    public let shippingInformation: String
    public let warrantyInformation: String
    public let returnPolicy: String
    public let images: [URL]
    public let rating: Double
    public let reviews: [Review]

    public struct Meta: Decodable, Sendable, Equatable {
        public let barcode: String
    }
}
