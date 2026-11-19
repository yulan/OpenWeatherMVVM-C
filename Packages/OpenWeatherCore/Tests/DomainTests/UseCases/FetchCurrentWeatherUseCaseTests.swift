//
//  FetchCurrentWeatherUseCaseTests.swift
//  DomainTests
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Testing

@Suite("FetchCurrentWeatherUseCase")
struct FetchCurrentWeatherUseCaseTests {
    @Test("Fetches the weather at the resolved coordinate")
    func fetchesWeatherAtCurrentLocation() async throws {
        let location = LocationRepositorySpy(result: .success(.paris))
        let weather = WeatherRepositorySpy(result: .success(.fixture()))
        let sut = DefaultFetchCurrentWeatherUseCase(locationRepository: location, weatherRepository: weather)

        let result = try await sut.execute()

        #expect(result == .fixture())
        #expect(weather.receivedCoordinates == [.paris])
    }

    @Test("A location failure short-circuits the weather request", arguments: [
        DomainError.locationPermissionDenied,
        .locationUnavailable,
        .cancelled,
    ])
    func locationFailureShortCircuits(error: DomainError) async {
        let location = LocationRepositorySpy(result: .failure(error))
        let weather = WeatherRepositorySpy(result: .success(.fixture()))
        let sut = DefaultFetchCurrentWeatherUseCase(locationRepository: location, weatherRepository: weather)

        await #expect(throws: error) { try await sut.execute() }
        #expect(weather.receivedCoordinates.isEmpty)
    }

    @Test("Weather failures are propagated unchanged")
    func propagatesWeatherFailure() async {
        let sut = DefaultFetchCurrentWeatherUseCase(
            locationRepository: LocationRepositorySpy(result: .success(.paris)),
            weatherRepository: WeatherRepositorySpy(result: .failure(.offline))
        )

        await #expect(throws: DomainError.offline) { try await sut.execute() }
    }
}
