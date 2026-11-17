import Foundation
import Testing

enum Fixture {
    static func data(_ name: String, extension fileExtension: String = "json") throws -> Data {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: fileExtension, subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }
}
