//
//  RemoteWeatherRepository.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

public struct RemoteWeatherRepository: WeatherRepository {
    private let apiClient: APIClient
    private let apiKey: String
    private let languageCode: String

    public init(apiClient: APIClient, apiKey: String, locale: Locale = .autoupdatingCurrent) {
        self.apiClient = apiClient
        self.apiKey = apiKey
        self.languageCode = locale.language.languageCode?.identifier ?? "en"
    }

    public func currentWeather(at coordinate: Coordinate) async throws(DomainError) -> Weather {
        // Fail fast instead of burning a request we know will be rejected.
        guard !apiKey.isEmpty else { throw .unauthorized }

        let endpoint = OpenWeatherAPI.currentWeather(at: coordinate, apiKey: apiKey, languageCode: languageCode)
        let dto: CurrentWeatherDTO
        do throws(NetworkError) {
            dto = try await apiClient.send(endpoint)
        } catch {
            throw error.domainError
        }
        return try dto.toDomain()
    }
}
