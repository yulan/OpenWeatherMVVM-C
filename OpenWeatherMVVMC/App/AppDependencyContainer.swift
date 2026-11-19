//
//  AppDependencyContainer.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import DataLayer
import Domain
import Foundation

/// Composition root: the only place that knows concrete implementations.
/// Coordinators ask it for fully-wired ViewModels; nothing else reaches into it.
@MainActor
final class AppDependencyContainer {
    private let fetchCurrentWeather: any FetchCurrentWeatherUseCase
    private let fetchCityStories: any FetchCityStoriesUseCase
    let urlOpener: any URLOpening

    init(
        fetchCurrentWeather: any FetchCurrentWeatherUseCase,
        fetchCityStories: any FetchCityStoriesUseCase,
        urlOpener: any URLOpening
    ) {
        self.fetchCurrentWeather = fetchCurrentWeather
        self.fetchCityStories = fetchCityStories
        self.urlOpener = urlOpener
    }

    static func live(configuration: AppConfiguration = AppConfiguration(bundle: .main)) -> AppDependencyContainer {
        let apiClient = APIClient(httpClient: URLSessionHTTPClient(session: .shared))

        let weatherUseCase = DefaultFetchCurrentWeatherUseCase(
            locationRepository: CoreLocationRepository(),
            weatherRepository: RemoteWeatherRepository(
                apiClient: apiClient,
                apiKey: configuration.openWeatherAPIKey
            )
        )
        let storiesUseCase = DefaultFetchCityStoriesUseCase(
            repository: RemoteStoryRepository(
                apiClient: apiClient,
                accessKey: configuration.unsplashAccessKey
            )
        )

        return AppDependencyContainer(
            fetchCurrentWeather: weatherUseCase,
            fetchCityStories: storiesUseCase,
            urlOpener: SystemURLOpener()
        )
    }

    // MARK: - Factories

    func makeWeatherViewModel() -> WeatherViewModel {
        WeatherViewModel(fetchCurrentWeather: fetchCurrentWeather)
    }

    func makeStoriesViewModel(city: String) -> StoriesViewModel {
        StoriesViewModel(city: city, fetchStories: fetchCityStories)
    }
}
