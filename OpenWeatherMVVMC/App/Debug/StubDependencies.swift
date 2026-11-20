//
//  StubDependencies.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

#if DEBUG
import Domain
import Foundation
import Synchronization

/// Deterministic, network-free dependencies for SwiftUI previews and UI tests.
/// Compiled out of Release builds.
final class StubFetchCurrentWeatherUseCase: FetchCurrentWeatherUseCase {
    private let results: Mutex<[Result<Weather, DomainError>]>
    private let delay: Duration

    /// Results are consumed in order; the last one repeats.
    init(_ results: [Result<Weather, DomainError>], delay: Duration = .milliseconds(300)) {
        precondition(!results.isEmpty)
        self.results = Mutex(results)
        self.delay = delay
    }

    func execute() async throws(DomainError) -> Weather {
        try? await Task.sleep(for: delay)
        let result = results.withLock { $0.count > 1 ? $0.removeFirst() : $0[0] }
        return try result.get()
    }
}

struct StubFetchCityStoriesUseCase: FetchCityStoriesUseCase {
    var imageBaseURL = "https://picsum.photos/seed"

    func execute(city: String) async throws(DomainError) -> [Story] {
        (1...5).map { index in
            Story(
                id: "\(index)",
                imageURL: URL(string: "\(imageBaseURL)/\(city)\(index)/1080/1920")!,
                caption: nil,
                photographerName: "Preview Photographer"
            )
        }
    }
}

extension Weather {
    static let sample = Weather(
        locationName: "Paris",
        countryCode: "FR",
        coordinate: Coordinate(latitude: 48.8566, longitude: 2.3522),
        conditions: [.init(id: 802, summary: "Clouds", detail: "scattered clouds", iconCode: "02d")],
        temperature: .init(current: 18.4, feelsLike: 17.9, min: 15.2, max: 21.6),
        pressure: 1015,
        humidity: 62,
        wind: .init(speed: 4.1, degrees: 230, gust: 7.2),
        cloudiness: 40,
        visibility: 10_000,
        sunrise: Date(timeIntervalSince1970: 1_650_264_000),
        sunset: Date(timeIntervalSince1970: 1_650_314_400),
        observedAt: Date(timeIntervalSince1970: 1_650_280_800),
        timeZone: TimeZone(identifier: "Europe/Paris")!
    )
}

extension AppDependencyContainer {
    static func uiTesting(_ scenario: UITestLaunch.Scenario) -> AppDependencyContainer {
        let weatherResults: [Result<Weather, DomainError>] = switch scenario {
        case .weatherSuccess: [.success(.sample)]
        case .permissionDenied: [.failure(.locationPermissionDenied)]
        case .offlineThenSuccess: [.failure(.offline), .success(.sample)]
        }
        return AppDependencyContainer(
            fetchCurrentWeather: StubFetchCurrentWeatherUseCase(weatherResults),
            // Unresolvable host: images fail fast, offline and deterministic.
            fetchCityStories: StubFetchCityStoriesUseCase(imageBaseURL: "https://stub.invalid"),
            imagePipeline: .offline,
            urlOpener: SystemURLOpener()
        )
    }
}

extension WeatherViewModel {
    static func preview(_ result: Result<Weather, DomainError>) -> WeatherViewModel {
        WeatherViewModel(fetchCurrentWeather: StubFetchCurrentWeatherUseCase([result]))
    }
}

extension StoriesViewModel {
    static var preview: StoriesViewModel {
        StoriesViewModel(city: "Paris", fetchStories: StubFetchCityStoriesUseCase(), imagePrefetcher: ImagePipeline.preview)
    }
}

extension ImagePipeline {
    /// Real network, for previews.
    static let preview = ImagePipeline.live()

    /// Every image fails immediately: deterministic UI tests, no network.
    static var offline: ImagePipeline {
        ImagePipeline { _ in throw URLError(.notConnectedToInternet) }
    }
}
#endif
