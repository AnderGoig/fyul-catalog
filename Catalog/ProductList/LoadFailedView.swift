import CatalogKit
import SwiftUI

struct LoadFailedView: View {
    let error: APIError
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            if error == .network {
                Label("Can't Reach the Catalog", systemImage: "wifi.slash")
            } else {
                Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
            }
        } description: {
            if error == .network {
                Text("Check your connection and try again.")
            } else {
                Text("Try again in a moment.")
            }
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}
