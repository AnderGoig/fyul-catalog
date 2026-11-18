import Foundation
import Testing
@testable import CatalogKit

@MainActor
@Suite("ImageLoader", .tags(.networking))
struct ImageLoaderTests {
    @Test func responseThatIsNotAnImageThrows() async throws {
        let (session, baseURL) = try StubURLProtocol.makeSession { request in
            (try .stub(for: request, status: 404), Data("<html>Not found</html>".utf8))
        }
        let loader = ImageLoader(session: session)
        let url = baseURL.appending(path: "thumbnail.webp")

        await #expect(throws: URLError.self) {
            try await loader.image(for: url)
        }
        #expect(loader.cachedImage(for: url) == nil)
    }

    @Test func secondLoadOfTheSameURLComesFromTheCache() async throws {
        let log = RequestLog()
        let (session, baseURL) = try StubURLProtocol.makeSession { request in
            log.record(request)
            return (try .stub(for: request), try Fixture.data("thumbnail", extension: "webp"))
        }
        let loader = ImageLoader(session: session)
        let url = baseURL.appending(path: "thumbnail.webp")

        let first = try await loader.image(for: url)
        let second = try await loader.image(for: url)

        #expect(log.requests.count == 1)
        #expect(second === first)
        #expect(loader.cachedImage(for: url) === first)
    }

    @Test func cancelledLoadThrowsCancellationError() async throws {
        let (session, baseURL) = try StubURLProtocol.makeSession { _ in throw URLError(.cancelled) }
        let loader = ImageLoader(session: session)

        await #expect(throws: CancellationError.self) {
            try await loader.image(for: baseURL.appending(path: "thumbnail.webp"))
        }
    }
}
