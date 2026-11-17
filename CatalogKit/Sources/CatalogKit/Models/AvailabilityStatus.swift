public enum AvailabilityStatus: String, Decodable, Sendable, Hashable {
    case inStock = "In Stock"
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
}
