public enum AvailabilityStatus: Decodable, Sendable, Hashable {
    case inStock
    case lowStock
    case outOfStock
    case other(String)

    public init(from decoder: any Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        switch value {
        case "In Stock": self = .inStock
        case "Low Stock": self = .lowStock
        case "Out of Stock": self = .outOfStock
        default: self = .other(value)
        }
    }
}
