//
//  CachedWeatherRepositoryTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Domain
import Foundation
import Testing

@Suite("CachedWeatherRepository")
struct CachedWeatherRepositoryTests {
    private let now = Weather.referenceDate.addingTimeInterval(2 * 60 * 60)

    private func makeSUT(
        remote: Result<Weather, DomainError>,
        saved: Weather? = nil,
        store: InMemoryWeatherStore? = nil
    ) -> (CachedWeatherRepository, InMemoryWeatherStore) {
        let store = store ?? InMemoryWeatherStore(saved)
        let now = now
        let sut = CachedWeatherRepository(
            remote: WeatherRepositoryStub(remote),
            store: store,
            policy: .init(maxAge: .seconds(24 * 60 * 60), maxDistanceInMeters: 25_000),
            now: { now }
        )
        return (sut, store)
    }

    @Test("Online: returns fresh weather and saves it")
    func savesFreshWeather() async throws {
        let fresh = Weather.fixture(name: "Fresh")
        let (sut, store) = makeSUT(remote: .success(fresh), saved: .fixture(name: "Old"))

        let weather = try await sut.currentWeather(at: .paris)

        #expect(weather == fresh)
        #expect(store.lastWeather() == fresh)
    }

    @Test("A failing save doesn't fail a successful request")
    func saveFailureIsIgnored() async throws {
        let (sut, _) = makeSUT(remote: .success(.fixture()), store: InMemoryWeatherStore(failsOnSave: true))

        let weather = try await sut.currentWeather(at: .paris)

        #expect(weather == .fixture())
    }

    @Test("Offline: serves the saved weather when it's recent and nearby")
    func offlineServesSavedWeather() async throws {
        let saved = Weather.fixture(name: "Saved", at: .pantin)
        let (sut, _) = makeSUT(remote: .failure(.offline), saved: saved)

        let weather = try await sut.currentWeather(at: .paris)

        #expect(weather == saved)
    }

    @Test("Offline with nothing saved: still offline")
    func offlineWithoutSavedWeather() async {
        let (sut, _) = makeSUT(remote: .failure(.offline))

        await #expect(throws: DomainError.offline) {
            try await sut.currentWeather(at: .paris)
        }
    }

    @Test("Offline: saved weather older than the max age is not served")
    func offlineIgnoresStaleWeather() async {
        let stale = Weather.fixture(observedAt: now.addingTimeInterval(-25 * 60 * 60))
        let (sut, _) = makeSUT(remote: .failure(.offline), saved: stale)

        await #expect(throws: DomainError.offline) {
            try await sut.currentWeather(at: .paris)
        }
    }

    @Test("Offline: saved weather for another city is not served")
    func offlineIgnoresFarAwayWeather() async {
        let (sut, _) = makeSUT(remote: .failure(.offline), saved: .fixture(name: "Lyon", at: .lyon))

        await #expect(throws: DomainError.offline) {
            try await sut.currentWeather(at: .paris)
        }
    }

    @Test(
        "Non-connectivity errors are never hidden behind saved data",
        arguments: [DomainError.unauthorized, .server(statusCode: 500), .invalidResponse, .cancelled]
    )
    func otherErrorsPropagate(error: DomainError) async {
        let (sut, _) = makeSUT(remote: .failure(error), saved: .fixture())

        await #expect(throws: error) {
            try await sut.currentWeather(at: .paris)
        }
    }

    @Test("Haversine distance matches known values")
    func distance() {
        #expect(Coordinate.paris.distance(to: .paris) == 0)
        #expect(abs(Coordinate.paris.distance(to: .lyon) - 392_000) < 2_000)
    }
}
