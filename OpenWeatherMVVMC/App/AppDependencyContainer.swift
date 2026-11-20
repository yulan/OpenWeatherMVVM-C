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
    private let imagePipeline: ImagePipeline
    let urlOpener: any URLOpening

    init(
        fetchCurrentWeather: any FetchCurrentWeatherUseCase,
        fetchCityStories: any FetchCityStoriesUseCase,
        imagePipeline: ImagePipeline,
        urlOpener: any URLOpening
    ) {
        self.fetchCurrentWeather = fetchCurrentWeather
        self.fetchCityStories = fetchCityStories
        self.imagePipeline = imagePipeline
        self.urlOpener = urlOpener
    }

    /// One shared pipeline: what a ViewModel prefetches is what a view finds.
    var imageLoader: any ImageLoading { imagePipeline }

    static func live(configuration: AppConfiguration = AppConfiguration(bundle: .main)) -> AppDependencyContainer {
        let apiClient = APIClient(httpClient: URLSessionHTTPClient(session: .shared))

        let weatherUseCase = DefaultFetchCurrentWeatherUseCase(
            locationRepository: CoreLocationRepository(),
            // Decorator: offline, the last saved weather is shown instead of an
            // error. Nothing above the Data layer knows about it.
            weatherRepository: CachedWeatherRepository(
                remote: RemoteWeatherRepository(
                    apiClient: apiClient,
                    apiKey: configuration.openWeatherAPIKey
                ),
                store: FileWeatherStore.inCachesDirectory()
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
            imagePipeline: .live(),
            urlOpener: SystemURLOpener()
        )
    }

    // MARK: - Factories

    func makeWeatherViewModel() -> WeatherViewModel {
        WeatherViewModel(fetchCurrentWeather: fetchCurrentWeather)
    }

    func makeStoriesViewModel(city: String) -> StoriesViewModel {
        StoriesViewModel(city: city, fetchStories: fetchCityStories, imagePrefetcher: imagePipeline)
    }
}
