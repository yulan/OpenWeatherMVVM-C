//
//  WeatherViewModelTests.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
@testable import OpenWeatherMVVMC
import Testing

@MainActor
@Suite("WeatherViewModel")
struct WeatherViewModelTests {
    private func makeSUT(
        _ results: Result<Weather, DomainError>...
    ) -> (WeatherViewModel, FetchCurrentWeatherUseCaseStub, WeatherNavigatorSpy) {
        let useCase = FetchCurrentWeatherUseCaseStub(results)
        let navigator = WeatherNavigatorSpy()
        let sut = WeatherViewModel(fetchCurrentWeather: useCase, locale: .testLocale)
        sut.navigator = navigator
        return (sut, useCase, navigator)
    }

    @Test("Starts idle")
    func startsIdle() {
        let (sut, useCase, _) = makeSUT(.success(.fixture()))
        #expect(sut.state == .idle)
        #expect(useCase.callCount == 0)
    }

    @Test("Appearing loads and exposes a display model")
    func appearLoads() async {
        let (sut, _, _) = makeSUT(.success(.fixture()))

        await sut.onAppear()

        #expect(sut.state == .loaded(WeatherDisplayModel(weather: .fixture(), locale: .testLocale)))
    }

    @Test("Appearing again does not reload")
    func appearOnlyOnce() async {
        let (sut, useCase, _) = makeSUT(.success(.fixture()))

        await sut.onAppear()
        await sut.onAppear()

        #expect(useCase.callCount == 1)
    }

    @Test("Failures map to a recoverable error", arguments: [
        (DomainError.locationPermissionDenied, ErrorPresentation.Recovery.openSettings),
        (.locationUnavailable, .retry),
        (.offline, .retry),
        (.unauthorized, .retry),
        (.server(statusCode: 500), .retry),
        (.invalidResponse, .retry),
        (.unknown, .retry),
    ])
    func failureMapsToError(error: DomainError, recovery: ErrorPresentation.Recovery) async throws {
        let (sut, _, _) = makeSUT(.failure(error))

        await sut.onAppear()

        guard case let .failed(presentation) = sut.state else {
            Issue.record("Expected failed state, got \(sut.state)")
            return
        }
        #expect(presentation.recovery == recovery)
        #expect(presentation == ErrorPresentation(error))
    }

    @Test("Cancellation before content is shown returns to idle so the next appearance retries")
    func cancellationReturnsToIdle() async {
        let (sut, useCase, _) = makeSUT(.failure(.cancelled), .success(.fixture()))

        await sut.onAppear()
        #expect(sut.state == .idle)

        await sut.onAppear()
        #expect(useCase.callCount == 2)
        #expect(sut.state == .loaded(WeatherDisplayModel(weather: .fixture(), locale: .testLocale)))
    }

    @Test("Retry after a failure loads the weather")
    func retryRecovers() async {
        let (sut, _, _) = makeSUT(.failure(.offline), .success(.fixture()))

        await sut.onAppear()
        await sut.recover(.retry)

        #expect(sut.state == .loaded(WeatherDisplayModel(weather: .fixture(), locale: .testLocale)))
    }

    @Test("Refreshing replaces the content with fresh data")
    func refreshReplacesContent() async {
        let (sut, _, _) = makeSUT(.success(.fixture(temperature: 10)), .success(.fixture(temperature: 25)))

        await sut.onAppear()
        await sut.load()

        guard case let .loaded(model) = sut.state else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(model.temperature == "25°")
    }

    @Test("Open Settings recovery is forwarded to the navigator")
    func openSettingsRecovery() async {
        let (sut, _, navigator) = makeSUT(.failure(.locationPermissionDenied))

        await sut.onAppear()
        await sut.recover(.openSettings)

        #expect(navigator.openAppSettingsCount == 1)
    }

    @Test("Tapping stories forwards the current city to the navigator")
    func storiesTapped() async {
        let (sut, _, navigator) = makeSUT(.success(.fixture(name: "Lyon")))

        await sut.onAppear()
        sut.storiesTapped()

        #expect(navigator.shownStoriesCities == ["Lyon"])
    }

    @Test("Tapping stories before any weather is loaded does nothing")
    func storiesTappedWithoutWeather() {
        let (sut, _, navigator) = makeSUT(.success(.fixture()))

        sut.storiesTapped()

        #expect(navigator.shownStoriesCities.isEmpty)
    }

    // MARK: Refresh failures

    @Test("A failed refresh keeps the content and reports a non-blocking error")
    func failedRefreshKeepsContent() async {
        let (sut, _, _) = makeSUT(.success(.fixture()), .failure(.offline))

        await sut.onAppear()
        await sut.load()

        #expect(sut.state == .loaded(WeatherDisplayModel(weather: .fixture(), locale: .testLocale)))
        #expect(sut.refreshError == ErrorPresentation(.offline))
        #expect(sut.isRefreshErrorPresented)
    }

    @Test("Dismissing the refresh alert clears the error")
    func dismissRefreshError() async {
        let (sut, _, _) = makeSUT(.success(.fixture()), .failure(.offline))
        await sut.onAppear()
        await sut.load()

        sut.isRefreshErrorPresented = false

        #expect(sut.refreshError == nil)
    }

    @Test("A successful retry from the refresh alert clears the error")
    func retryClearsRefreshError() async {
        let (sut, _, _) = makeSUT(.success(.fixture()), .failure(.offline), .success(.fixture(temperature: 30)))
        await sut.onAppear()
        await sut.load()

        await sut.recover(.retry)

        #expect(sut.refreshError == nil)
    }

    // MARK: Returning from Settings

    @Test("Coming back to the foreground after denying location reloads automatically")
    func reloadsWhenReturningFromSettings() async {
        let (sut, useCase, _) = makeSUT(.failure(.locationPermissionDenied), .success(.fixture()))
        await sut.onAppear()

        await sut.sceneDidBecomeActive()

        #expect(useCase.callCount == 2)
        #expect(sut.state == .loaded(WeatherDisplayModel(weather: .fixture(), locale: .testLocale)))
    }

    @Test("Coming back to the foreground doesn't reload for other errors or loaded content", arguments: [
        Result<Weather, DomainError>.failure(.offline),
        .success(.fixture()),
    ])
    func noReloadOnForegroundOtherwise(result: Result<Weather, DomainError>) async {
        let (sut, useCase, _) = makeSUT(result)
        await sut.onAppear()

        await sut.sceneDidBecomeActive()

        #expect(useCase.callCount == 1)
    }
}
