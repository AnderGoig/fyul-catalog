import CatalogKit
import SwiftUI

@main
struct CatalogApp: App {
    @State private var listViewModel: ProductListViewModel
    private let imageLoader: ImageLoader

    init() {
        let session = URLSession.shared
        let client = APIClient(baseURL: URL(string: "https://dummyjson.com")!, session: session)
        _listViewModel = State(initialValue: ProductListViewModel(loader: client))
        imageLoader = ImageLoader(session: session)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ProductListView(viewModel: listViewModel)
            }
            .environment(\.imageLoader, imageLoader)
        }
    }
}
