import UIKit

@MainActor
public final class ImageLoader {
    private let session: URLSession
    private let cache = NSCache<NSURL, UIImage>()

    public init(session: URLSession) {
        self.session = session
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    public func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    public func image(for url: URL) async throws -> UIImage {
        if let cached = cachedImage(for: url) {
            return cached
        }
        let image = try await Self.download(url, session: session)
        let decodedBytes = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: decodedBytes)
        return image
    }

    @concurrent private static func download(_ url: URL, session: URLSession) async throws -> UIImage {
        let data: Data
        do {
            (data, _) = try await session.data(from: url)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        }
        guard let image = UIImage(data: data)?.preparingForDisplay() else {
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }
}
