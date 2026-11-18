import Foundation
import Testing
@testable import CatalogKit

@Suite("APIClient")
struct APIClientTests {
    @Test func pageRequestsTheListFieldsForThatPage() async throws {
        let log = RequestLog()
        let (session, baseURL) = try StubURLProtocol.makeSession { request in
            log.record(request)
            return (try .stub(for: request), try Fixture.data("page-skip7-limit3"))
        }
        let client = APIClient(baseURL: baseURL, session: session)

        let page = try await client.page(skip: 7, limit: 3)

        #expect(page.products.map(\.id) == [8, 9, 10])
        let url = try #require(log.requests.first?.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/products")
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        #expect(query["skip"] == "7")
        #expect(query["limit"] == "3")
        #expect(query["select"] == "title,price,stock,availabilityStatus,category,thumbnail")
    }

    @Test func productRequestsThatProductByID() async throws {
        let log = RequestLog()
        let (session, baseURL) = try StubURLProtocol.makeSession { request in
            log.record(request)
            return (try .stub(for: request), try Fixture.data("product-1-with-brand"))
        }
        let client = APIClient(baseURL: baseURL, session: session)

        let product = try await client.product(id: 1)

        #expect(product.id == 1)
        #expect(log.requests.first?.url?.path() == "/products/1")
    }

    @Test func everyRequestTimesOutAfterFifteenSeconds() async throws {
        let log = RequestLog()
        let (session, baseURL) = try StubURLProtocol.makeSession { request in
            log.record(request)
            let fixture = request.url?.path() == "/products" ? "page-skip7-limit3" : "product-1-with-brand"
            return (try .stub(for: request), try Fixture.data(fixture))
        }
        let client = APIClient(baseURL: baseURL, session: session)

        _ = try await client.page(skip: 0, limit: 30)
        _ = try await client.product(id: 1)

        #expect(log.requests.map(\.timeoutInterval) == [15, 15])
    }

    @Test func requestAdapterChangesTheRequestBeforeItIsSent() async throws {
        let log = RequestLog()
        let (session, baseURL) = try StubURLProtocol.makeSession { request in
            log.record(request)
            return (try .stub(for: request), try Fixture.data("product-1-with-brand"))
        }
        let client = APIClient(baseURL: baseURL, session: session) { request in
            var request = request
            request.url = request.url?.appending(queryItems: [URLQueryItem(name: "delay", value: "3000")])
            return request
        }

        _ = try await client.product(id: 1)

        #expect(log.requests.first?.url?.query() == "delay=3000")
    }

    @Test func notFoundStatusThrowsNotFound() async throws {
        let (session, baseURL) = try StubURLProtocol.makeSession { request in
            (try .stub(for: request, status: 404), try Fixture.data("not-found-9999"))
        }
        let client = APIClient(baseURL: baseURL, session: session)

        await #expect(throws: APIError.notFound) {
            try await client.product(id: 9999)
        }
    }

    @Test func otherErrorStatusThrowsServerWithThatStatus() async throws {
        let (session, baseURL) = try StubURLProtocol.makeSession { request in
            (try .stub(for: request, status: 503), try Fixture.data("http-503"))
        }
        let client = APIClient(baseURL: baseURL, session: session)

        await #expect(throws: APIError.server(status: 503)) {
            try await client.page(skip: 0, limit: 30)
        }
    }

    @Test(arguments: [
        URLError.Code.notConnectedToInternet,
        .networkConnectionLost,
        .timedOut,
        .cannotFindHost,
        .secureConnectionFailed,
    ])
    func transportFailureThrowsNetwork(code: URLError.Code) async throws {
        let (session, baseURL) = try StubURLProtocol.makeSession { _ in throw URLError(code) }
        let client = APIClient(baseURL: baseURL, session: session)

        await #expect(throws: APIError.network) {
            try await client.page(skip: 0, limit: 30)
        }
    }

    @Test func cancelledRequestThrowsCancellationError() async throws {
        let (session, baseURL) = try StubURLProtocol.makeSession { _ in throw URLError(.cancelled) }
        let client = APIClient(baseURL: baseURL, session: session)

        await #expect(throws: CancellationError.self) {
            try await client.page(skip: 0, limit: 30)
        }
    }

    @Test func bodyThatDoesNotMatchTheModelThrowsDecoding() async throws {
        let (session, baseURL) = try StubURLProtocol.makeSession { request in
            (try .stub(for: request), Data("<html>Gateway</html>".utf8))
        }
        let client = APIClient(baseURL: baseURL, session: session)

        await #expect(throws: APIError.decoding) {
            try await client.page(skip: 0, limit: 30)
        }
    }
}
