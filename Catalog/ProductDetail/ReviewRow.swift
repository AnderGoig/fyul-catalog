import CatalogKit
import SwiftUI

struct ReviewRow: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(review.reviewerName)
                    .font(.headline)
                Spacer()
                Text(review.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(review.rating) out of 5")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(review.comment)
        }
        .accessibilityElement(children: .combine)
    }
}
