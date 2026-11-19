//
//  EndpointTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Foundation
import Testing

@Suite("Endpoint")
struct EndpointTests {
    private struct Dummy: Decodable, Sendable {}

    @Test("Builds URL, query, method and headers")
    func buildsRequest() throws {
        let endpoint = Endpoint<Dummy>(
            baseURL: URL(string: "https://api.example.com")!,
            path: "v1/items",
            queryItems: [URLQueryItem(name: "q", value: "a b&c")],
            headers: ["X-Key": "secret"]
        )

        let request = try endpoint.makeRequest(timeout: 7)

        #expect(request.url?.absoluteString == "https://api.example.com/v1/items?q=a%20b%26c")
        #expect(request.httpMethod == "GET")
        #expect(request.timeoutInterval == 7)
        #expect(request.value(forHTTPHeaderField: "X-Key") == "secret")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("Omits the query string when there are no query items")
    func noQueryItems() throws {
        let request = try Endpoint<Dummy>(baseURL: URL(string: "https://api.example.com")!, path: "ping").makeRequest()
        #expect(request.url?.absoluteString == "https://api.example.com/ping")
    }
}
