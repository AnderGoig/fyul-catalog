public enum APIError: Error, Equatable {
    case network
    case server(status: Int)
    case notFound
    case decoding
}
