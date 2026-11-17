import Foundation

public struct Review: Decodable, Sendable, Equatable {
    public let rating: Int
    public let comment: String
    public let date: Date
    public let reviewerName: String
}
