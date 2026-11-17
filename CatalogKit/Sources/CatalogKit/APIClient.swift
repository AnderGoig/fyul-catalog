import Foundation
import os

public struct APIClient: Sendable {
    private static let logger = Logger(subsystem: "com.andergoig.Catalog", category: "APIClient")

    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession) {
        self.baseURL = baseURL
        self.session = session
    }

    public func page(skip: Int, limit: Int) async throws -> ProductPage {
        let url = baseURL.appending(path: "products").appending(queryItems: [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "select", value: ProductSummary.selectedFields),
        ])
        return try await send(URLRequest(url: url))
    }

    public func product(id: Int) async throws -> Product {
        try await send(URLRequest(url: baseURL.appending(path: "products/\(id)")))
    }

    @concurrent private func send<Response: Decodable & Sendable>(_ request: URLRequest) async throws -> Response {
        var request = request
        request.timeoutInterval = 15
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError {
            Self.logger.error("\(request.url?.path() ?? "", privacy: .public) failed: URLError \(error.code.rawValue)")
            throw APIError.network
        }
        if let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) {
            Self.logger.error("\(request.url?.path() ?? "", privacy: .public) returned HTTP \(status)")
            throw status == 404 ? APIError.notFound : APIError.server(status: status)
        }
        do {
            return try Self.makeDecoder().decode(Response.self, from: data)
        } catch {
            Self.logger.error("\(request.url?.path() ?? "", privacy: .public) didn't decode: \(String(describing: error), privacy: .public)")
            throw APIError.decoding
        }
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            return try Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string)
        }
        return decoder
    }
}
