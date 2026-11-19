//
//  APIClientTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Foundation
import Testing

@Suite("APIClient")
struct APIClientTests {
    private struct Item: Decodable, Sendable, Equatable { let id: Int }
    private let endpoint = Endpoint<Item>(baseURL: URL(string: "https://api.example.com")!, path: "item")

    @Test("Decodes a 2xx body", arguments: [200, 204, 299])
    func decodesSuccess(status: Int) async throws {
        let sut = APIClient(httpClient: HTTPClientStub.json(#"{"id": 7}"#, status: status))
        #expect(try await sut.send(endpoint) == Item(id: 7))
    }

    @Test("Translates failures into NetworkError", arguments: [
        (HTTPClientStub.Reply.response(status: 404, body: Data()), NetworkError.httpStatus(404)),
        (.response(status: 500, body: Data()), .httpStatus(500)),
        (.failure(URLError(.notConnectedToInternet)), .transport(.notConnectedToInternet)),
        (.failure(URLError(.cancelled)), .cancelled),
        (.failure(CancellationError()), .cancelled),
        (.failure(NSError(domain: "x", code: 1)), .transport(.unknown)),
    ])
    func translatesFailures(reply: HTTPClientStub.Reply, expected: NetworkError) async {
        let sut = APIClient(httpClient: HTTPClientStub(reply))
        await #expect(throws: expected) { try await sut.send(endpoint) }
    }

    @Test("A malformed body is a decoding error")
    func malformedBody() async {
        let sut = APIClient(httpClient: HTTPClientStub.json(#"{"identifier": 7}"#))
        do {
            _ = try await sut.send(endpoint)
            Issue.record("Expected a decoding error")
        } catch {
            guard case .decoding = error else {
                Issue.record("Expected .decoding, got \(error)")
                return
            }
        }
    }
}
