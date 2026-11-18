import Foundation
import Testing
@testable import Catalog

@Suite("Debug network switches")
struct DebugNetworkSwitchesTests {
    @Test func failAfterLetsTheFirstRequestsThroughAndDelaysEveryRequest() throws {
        let switches = DebugNetworkSwitches(environment: [
            "CATALOG_DELAY_MS": "3000",
            "CATALOG_FAIL_STATUS": "404",
            "CATALOG_FAIL_AFTER": "1",
        ])
        let adapt = try #require(switches.makeAdapter())

        let first = adapt(URLRequest(url: try #require(URL(string: "https://dummyjson.com/products?limit=30"))))
        let second = adapt(URLRequest(url: try #require(URL(string: "https://dummyjson.com/products/1"))))

        #expect(first.url?.absoluteString == "https://dummyjson.com/products?limit=30&delay=3000")
        #expect(second.url?.absoluteString == "https://dummyjson.com/http/404?delay=3000")
    }

    @Test func noSwitchesMeansNoAdapter() {
        #expect(DebugNetworkSwitches(environment: [:]).makeAdapter() == nil)
    }
}
