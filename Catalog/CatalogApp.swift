import CatalogKit
import SwiftUI

@main
struct CatalogApp: App {
    @State private var listViewModel: ProductListViewModel
    private let client: APIClient
    private let imageLoader: ImageLoader

    init() {
        guard let baseURL = URL(string: "https://dummyjson.com") else {
            fatalError("The DummyJSON base URL is not a valid URL.")
        }
        let session = URLSession.shared
        client = APIClient(
            baseURL: baseURL,
            session: session,
            requestAdapter: Self.debugRequestAdapter()
        )
        imageLoader = ImageLoader(session: session)
        _listViewModel = State(initialValue: ProductListViewModel(loader: client))
    }

    private static func debugRequestAdapter() -> (@Sendable (URLRequest) -> URLRequest)? {
        #if DEBUG
        DebugNetworkSwitches().makeAdapter()
        #else
        nil
        #endif
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ProductListView(viewModel: listViewModel, loader: client)
            }
            .environment(\.imageLoader, imageLoader)
        }
    }
}
