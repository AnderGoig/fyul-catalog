#if DEBUG
import Foundation
import os

struct DebugNetworkSwitches {
    private let delayMilliseconds: Int?
    private let failStatus: Int?
    private let failAfter: Int

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        delayMilliseconds = environment["CATALOG_DELAY_MS"].flatMap(Int.init)
        failStatus = environment["CATALOG_FAIL_STATUS"].flatMap(Int.init)
        failAfter = environment["CATALOG_FAIL_AFTER"].flatMap(Int.init) ?? 0
    }

    func makeAdapter() -> (@Sendable (URLRequest) -> URLRequest)? {
        guard delayMilliseconds != nil || failStatus != nil else { return nil }
        let delayMilliseconds = delayMilliseconds
        let failStatus = failStatus
        let failAfter = failAfter
        let sentCount = OSAllocatedUnfairLock(initialState: 0)

        return { request in
            let index = sentCount.withLock { count in
                defer { count += 1 }
                return count
            }
            guard let url = request.url,
                  var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            else { return request }

            if let failStatus, index >= failAfter {
                components.path = "/http/\(failStatus)"
            }
            if let delayMilliseconds {
                components.queryItems = (components.queryItems ?? []) + [
                    URLQueryItem(name: "delay", value: String(delayMilliseconds)),
                ]
            }
            var adapted = request
            adapted.url = components.url ?? url
            return adapted
        }
    }
}
#endif
