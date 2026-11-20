//
//  ContainerStub.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation
@testable import OpenWeatherMVVMC

extension AppDependencyContainer {
    static func stub(
        weather: Weather = .fixture(),
        stories: [Story] = Story.fixtures,
        urlOpener: any URLOpening = URLOpenerSpy()
    ) -> AppDependencyContainer {
        AppDependencyContainer(
            fetchCurrentWeather: FetchCurrentWeatherUseCaseStub(.success(weather)),
            fetchCityStories: FetchCityStoriesUseCaseStub(.success(stories)),
            imagePipeline: ImagePipeline { _ in throw URLError(.notConnectedToInternet) },
            urlOpener: urlOpener
        )
    }
}
