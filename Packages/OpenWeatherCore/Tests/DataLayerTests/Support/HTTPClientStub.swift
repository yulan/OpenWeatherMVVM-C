//
//  HTTPClientStub.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Foundation
import Synchronization

/// Records requests and replays a canned response.
final class HTTPClientStub: HTTPClient {
    enum Reply: Sendable {
        case response(status: Int, body: Data)
        case failure(any Error & Sendable)
    }

    private let reply: Reply
    private let requests = Mutex<[URLRequest]>([])

    init(_ reply: Reply) {
        self.reply = reply
    }

    static func json(_ body: String, status: Int = 200) -> HTTPClientStub {
        HTTPClientStub(.response(status: status, body: Data(body.utf8)))
    }

    var receivedRequests: [URLRequest] { requests.withLock { $0 } }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.withLock { $0.append(request) }
        switch reply {
        case let .response(status, body):
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (body, response)
        case let .failure(error):
            throw error
        }
    }
}

extension URLRequest {
    func queryValue(_ name: String) -> String? {
        url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
            .queryItems?.first { $0.name == name }?.value
    }
}
