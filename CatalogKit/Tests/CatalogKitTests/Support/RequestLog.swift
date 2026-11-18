import Foundation
import os

final class RequestLog: Sendable {
    private let storage = OSAllocatedUnfairLock<[URLRequest]>(initialState: [])

    var requests: [URLRequest] { storage.withLock { $0 } }

    func record(_ request: URLRequest) {
        storage.withLock { $0.append(request) }
    }
}
