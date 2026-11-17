import CatalogKit
import SwiftUI

@main
struct CatalogApp: App {
    @State private var listViewModel: ProductListViewModel
    private let client: APIClient
    private let imageLoader: ImageLoader

    init() {
        let session = URLSession.shared
        client = APIClient(baseURL: URL(string: "https://dummyjson.com")!, session: session)
        imageLoader = ImageLoader(session: session)
        _listViewModel = State(initialValue: ProductListViewModel(loader: client))
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
