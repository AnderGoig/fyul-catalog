import SwiftUI

struct RefreshFailedRow: View {
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Couldn't refresh. Showing earlier results.", systemImage: "exclamationmark.arrow.circlepath")
            Button("Retry", action: retry)
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}
