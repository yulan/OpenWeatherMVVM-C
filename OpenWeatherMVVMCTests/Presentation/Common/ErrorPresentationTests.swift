//
//  ErrorPresentationTests.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
@testable import OpenWeatherMVVMC
import Testing

@Suite("ErrorPresentation")
struct ErrorPresentationTests {
    @Test("Cancellation is never shown to the user")
    func cancellationIsSilent() {
        #expect(ErrorPresentation(.cancelled) == nil)
    }

    @Test("Every visible error has localized wording and the right recovery", arguments: [
        (DomainError.locationPermissionDenied, ErrorPresentation.Recovery.openSettings, AppSymbol.locationDenied),
        (.locationUnavailable, .retry, .locationUnavailable),
        (.offline, .retry, .offline),
        (.unauthorized, .retry, .unauthorized),
        (.server(statusCode: 503), .retry, .serverError),
        (.invalidResponse, .retry, .genericError),
        (.unknown, .retry, .genericError),
    ])
    func mapping(error: DomainError, recovery: ErrorPresentation.Recovery, symbol: AppSymbol) throws {
        let sut = try #require(ErrorPresentation(error))
        #expect(sut.recovery == recovery)
        #expect(sut.symbol == symbol)
        #expect(!sut.title.isEmpty)
        #expect(!sut.message.isEmpty)
        // A missing catalog entry would surface the raw key.
        #expect(!sut.title.hasPrefix("error."))
        #expect(!sut.message.hasPrefix("error."))
    }

    @Test("Server errors include the status code")
    func serverStatusCode() throws {
        let sut = try #require(ErrorPresentation(.server(statusCode: 503)))
        #expect(sut.message.contains("503"))
    }
}
