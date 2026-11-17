import Foundation
import Testing
@testable import CatalogKit

@Suite("Decoding payloads captured from the live API")
struct DecodingTests {
    @Test func pageDecodesSummariesAndPagingFields() throws {
        let page = try APIClient.makeDecoder().decode(ProductPage.self, from: Fixture.data("page-skip7-limit3"))

        #expect(page.total == 194)
        #expect(page.skip == 7)
        #expect(page.limit == 3)
        #expect(page.products.map(\.id) == [8, 9, 10])

        let lowStock = page.products[1]
        #expect(lowStock.title == "Dolce Shine Eau de")
        #expect(lowStock.price == 69.99)
        #expect(lowStock.stock == 4)
        #expect(lowStock.availabilityStatus == .lowStock)
        #expect(lowStock.category == "fragrances")
        #expect(lowStock.thumbnail.lastPathComponent == "thumbnail.webp")
    }

    @Test func productDecodesTheDetailFields() throws {
        let product = try APIClient.makeDecoder().decode(Product.self, from: Fixture.data("product-1-with-brand"))

        #expect(product.id == 1)
        #expect(product.title == "Essence Mascara Lash Princess")
        #expect(product.description.hasPrefix("The Essence Mascara Lash Princess"))
        #expect(product.brand == "Essence")
        #expect(product.sku == "BEA-ESS-ESS-001")
        #expect(product.meta.barcode == "5784719087687")
        #expect(product.category == "beauty")
        #expect(product.price == 9.99)
        #expect(product.discountPercentage == 10.48)
        #expect(product.stock == 99)
        #expect(product.availabilityStatus == .inStock)
        #expect(product.minimumOrderQuantity == 48)
        #expect(product.shippingInformation == "Ships in 3-5 business days")
        #expect(product.warrantyInformation == "1 week warranty")
        #expect(product.returnPolicy == "No return policy")
        #expect(product.images.map(\.lastPathComponent) == ["1.webp"])
        #expect(product.rating == 2.56)
        #expect(product.reviews.count == 3)
        #expect(product.reviews.first?.reviewerName == "Eleanor Collins")
        #expect(product.reviews.first?.rating == 3)
        #expect(product.reviews.first?.comment == "Would not recommend!")
    }

    @Test func productWithoutBrandDecodesWithNilBrand() throws {
        let product = try APIClient.makeDecoder().decode(Product.self, from: Fixture.data("product-16-without-brand"))

        #expect(product.id == 16)
        #expect(product.brand == nil)
    }

    @Test func reviewDateKeepsItsFractionalSeconds() throws {
        let product = try APIClient.makeDecoder().decode(Product.self, from: Fixture.data("product-1-with-brand"))
        let date = try #require(product.reviews.first?.date)

        let expected = Date(timeIntervalSince1970: 1_746_006_062.053)
        #expect(abs(date.timeIntervalSince(expected)) < 0.001)
    }
}
