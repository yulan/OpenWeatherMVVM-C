//
//  WeatherRepository.swift
//  Domain
//
//  Created by Lan YU on 19/11/2026.
//

public protocol WeatherRepository: Sendable {
    func currentWeather(at coordinate: Coordinate) async throws(DomainError) -> Weather
}
