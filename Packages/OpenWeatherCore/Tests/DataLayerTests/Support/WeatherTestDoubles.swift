//
//  WeatherTestDoubles.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Domain
import Foundation
import Synchronization

final class WeatherRepositoryStub: WeatherRepository {
    private let result: Result<Weather, DomainError>
    private let calls = Mutex(0)

    init(_ result: Result<Weather, DomainError>) {
        self.result = result
    }

    var callCount: Int { calls.withLock { $0 } }

    func currentWeather(at coordinate: Coordinate) async throws(DomainError) -> Weather {
        calls.withLock { $0 += 1 }
        return try result.get()
    }
}

final class InMemoryWeatherStore: WeatherStore {
    struct DiskFull: Error {}

    private let saved: Mutex<Weather?>
    private let failsOnSave: Bool

    init(_ weather: Weather? = nil, failsOnSave: Bool = false) {
        self.saved = Mutex(weather)
        self.failsOnSave = failsOnSave
    }

    func lastWeather() -> Weather? { saved.withLock { $0 } }

    func save(_ weather: Weather) throws {
        if failsOnSave { throw DiskFull() }
        saved.withLock { $0 = weather }
    }
}

extension Coordinate {
    static let paris = Coordinate(latitude: 48.8566, longitude: 2.3522)
    /// About 6 km from `.paris`.
    static let pantin = Coordinate(latitude: 48.8937, longitude: 2.4064)
    /// About 390 km from `.paris`.
    static let lyon = Coordinate(latitude: 45.7640, longitude: 4.8357)
}

extension Weather {
    static let referenceDate = Date(timeIntervalSince1970: 1_650_280_800)

    static func fixture(
        name: String = "Paris",
        at coordinate: Coordinate = .paris,
        observedAt: Date = referenceDate,
        wind: Wind? = .init(speed: 3.1, degrees: 180, gust: 6.5)
    ) -> Weather {
        Weather(
            locationName: name,
            countryCode: "FR",
            coordinate: coordinate,
            conditions: [.init(id: 800, summary: "Clear", detail: "clear sky", iconCode: "01d")],
            temperature: .init(current: 18.5, feelsLike: 18.0, min: 16.5, max: 20.0),
            pressure: 1013,
            humidity: 60,
            wind: wind,
            cloudiness: 0,
            visibility: 10_000,
            sunrise: Date(timeIntervalSince1970: 1_650_264_000),
            sunset: Date(timeIntervalSince1970: 1_650_314_400),
            observedAt: observedAt,
            timeZone: TimeZone(secondsFromGMT: 7200)!
        )
    }
}
