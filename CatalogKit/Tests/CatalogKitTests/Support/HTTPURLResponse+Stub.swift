import Foundation
import Testing

extension HTTPURLResponse {
    static func stub(for request: URLRequest, status: Int = 200) throws -> HTTPURLResponse {
        let url = try #require(request.url)
        return try #require(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
    }
}
