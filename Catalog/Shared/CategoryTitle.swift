import Foundation

extension String {
    var categoryTitle: String {
        replacing("-", with: " ").localizedCapitalized
    }
}
