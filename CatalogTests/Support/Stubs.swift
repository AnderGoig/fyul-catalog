import CatalogKit
import Foundation

extension ProductPage {
    static func stub(ids: ClosedRange<Int>, skip: Int, total: Int) -> ProductPage {
        ProductPage(products: ids.map(ProductSummary.stub), total: total, skip: skip, limit: 30)
    }
}

extension Product {
    static func stub(id: Int, stock: Int = 3) throws -> Product {
        let json: [String: Any] = [
            "id": id,
            "title": "Product \(id)",
            "description": "A product.",
            "sku": "SKU-\(id)",
            "meta": ["barcode": "000\(id)"],
            "category": "beauty",
            "price": 9.99,
            "discountPercentage": 10.5,
            "stock": stock,
            "availabilityStatus": "Low Stock",
            "minimumOrderQuantity": 5,
            "shippingInformation": "Ships in 1 week",
            "warrantyInformation": "No warranty",
            "returnPolicy": "No return policy",
            "images": ["https://cdn.example/\(id)/1.webp"],
            "rating": 4.5,
            "reviews": [],
        ]
        return try JSONDecoder().decode(Product.self, from: JSONSerialization.data(withJSONObject: json))
    }
}

extension ProductSummary {
    static func stub(id: Int) -> ProductSummary {
        ProductSummary(
            id: id,
            title: "Product \(id)",
            price: 9.99,
            stock: 5,
            availabilityStatus: .inStock,
            category: "beauty",
            thumbnail: URL(filePath: "/thumbnails/\(id).webp")
        )
    }
}
