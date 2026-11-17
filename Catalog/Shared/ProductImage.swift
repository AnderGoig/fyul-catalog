import CatalogKit
import SwiftUI

struct ProductImage: View {
    let url: URL

    @Environment(\.imageLoader) private var loader
    @State private var loaded: (url: URL, image: UIImage)?
    @State private var failedURL: URL?

    var body: some View {
        ZStack {
            if let image = loadedImage ?? loader?.cachedImage(for: url) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if failedURL == url {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.fill.tertiary, in: .rect(cornerRadius: 8))
        .task(id: url) { await load() }
    }

    private var loadedImage: UIImage? {
        loaded?.url == url ? loaded?.image : nil
    }

    private func load() async {
        guard let loader, loadedImage == nil else { return }
        do {
            loaded = (url, try await loader.image(for: url))
        } catch is CancellationError {
        } catch {
            failedURL = url
        }
    }
}

extension EnvironmentValues {
    @Entry var imageLoader: ImageLoader?
}
