import Foundation

extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    static var catalogPrice: Self {
        .currency(code: "USD")
    }
}
