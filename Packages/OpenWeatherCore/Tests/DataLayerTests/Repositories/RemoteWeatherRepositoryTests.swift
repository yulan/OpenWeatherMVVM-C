//
//  RemoteWeatherRepositoryTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Domain
import Foundation
import Testing

@Suite("RemoteWeatherRepository")
struct RemoteWeatherRepositoryTests {
    private func makeSUT(_ client: HTTPClientStub, apiKey: String = "KEY") -> RemoteWeatherRepository {
        RemoteWeatherRepository(
            apiClient: APIClient(httpClient: client),
            apiKey: apiKey,
            locale: Locale(identifier: "fr_FR")
        )
    }

    @Test("Builds the OpenWeather request with coordinate, units, language and key")
    func buildsRequest() async throws {
        let client = HTTPClientStub.json(Fixtures.currentWeather)

        _ = try await makeSUT(client).currentWeather(at: Coordinate(latitude: 48.5, longitude: 2.25))

        let request = try #require(client.receivedRequests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.host() == "api.openweathermap.org")
        #expect(request.url?.path() == "/data/2.5/weather")
        #expect(request.queryValue("lat") == "48.5")
        #expect(request.queryValue("lon") == "2.25")
        #expect(request.queryValue("units") == "metric")
        #expect(request.queryValue("lang") == "fr")
        #expect(request.queryValue("appid") == "KEY")
    }

    @Test("Returns the mapped domain model on success")
    func returnsDomainModel() async throws {
        let weather = try await makeSUT(.json(Fixtures.currentWeather)).currentWeather(at: .init(latitude: 0, longitude: 0))
        #expect(weather.locationName == "Pantin")
    }

    @Test("Fails fast without hitting the network when the API key is missing")
    func missingKeyFailsFast() async {
        let client = HTTPClientStub.json(Fixtures.currentWeather)

        await #expect(throws: DomainError.unauthorized) {
            try await makeSUT(client, apiKey: "").currentWeather(at: .init(latitude: 0, longitude: 0))
        }
        #expect(client.receivedRequests.isEmpty)
    }

    @Test("Network failures surface as domain errors")
    func surfacesDomainErrors() async {
        await #expect(throws: DomainError.offline) {
            try await makeSUT(HTTPClientStub(.failure(URLError(.notConnectedToInternet))))
                .currentWeather(at: .init(latitude: 0, longitude: 0))
        }
    }

    @Test("A payload that can't be mapped is an invalid response")
    func unmappablePayload() async {
        await #expect(throws: DomainError.invalidResponse) {
            try await makeSUT(.json(Fixtures.currentWeatherWithoutMain)).currentWeather(at: .init(latitude: 0, longitude: 0))
        }
    }
}
