//
//  NetworkErrorTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Domain
import Foundation
import Testing

@Suite("NetworkError → DomainError")
struct NetworkErrorTests {
    @Test("Maps every network failure to a domain error", arguments: [
        (NetworkError.cancelled, DomainError.cancelled),
        (.transport(.notConnectedToInternet), .offline),
        (.transport(.networkConnectionLost), .offline),
        (.transport(.timedOut), .offline),
        (.transport(.cannotFindHost), .offline),
        (.transport(.badServerResponse), .unknown),
        (.httpStatus(401), .unauthorized),
        (.httpStatus(403), .unauthorized),
        (.httpStatus(429), .server(statusCode: 429)),
        (.httpStatus(503), .server(statusCode: 503)),
        (.decoding("…"), .invalidResponse),
        (.invalidRequest, .unknown),
    ])
    func mapping(networkError: NetworkError, expected: DomainError) {
        #expect(networkError.domainError == expected)
    }
}
