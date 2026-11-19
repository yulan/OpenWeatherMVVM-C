//
//  FetchCurrentWeatherUseCase.swift
//  Domain
//
//  Created by Lan YU on 19/11/2026.
//

/// Locates the user, then fetches the weather for that position.
public protocol FetchCurrentWeatherUseCase: Sendable {
    func execute() async throws(DomainError) -> Weather
}

public struct DefaultFetchCurrentWeatherUseCase: FetchCurrentWeatherUseCase {
    private let locationRepository: any LocationRepository
    private let weatherRepository: any WeatherRepository

    public init(locationRepository: any LocationRepository, weatherRepository: any WeatherRepository) {
        self.locationRepository = locationRepository
        self.weatherRepository = weatherRepository
    }

    public func execute() async throws(DomainError) -> Weather {
        // Location is resolved on every call on purpose: a retry after a
        // network failure should reflect where the user is *now*.
        let coordinate = try await locationRepository.currentCoordinate()
        try Self.checkCancellation()
        return try await weatherRepository.currentWeather(at: coordinate)
    }

    private static func checkCancellation() throws(DomainError) {
        if Task.isCancelled { throw .cancelled }
    }
}
