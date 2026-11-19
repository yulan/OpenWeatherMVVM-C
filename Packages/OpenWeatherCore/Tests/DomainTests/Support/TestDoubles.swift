//
//  TestDoubles.swift
//  DomainTests
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation
import Synchronization

final class LocationRepositorySpy: LocationRepository {
    private let result: Result<Coordinate, DomainError>
    private let calls = Mutex(0)

    init(result: Result<Coordinate, DomainError>) {
        self.result = result
    }

    var callCount: Int { calls.withLock { $0 } }

    func currentCoordinate() async throws(DomainError) -> Coordinate {
        calls.withLock { $0 += 1 }
        return try result.get()
    }
}

final class WeatherRepositorySpy: WeatherRepository {
    private let result: Result<Weather, DomainError>
    private let received = Mutex<[Coordinate]>([])

    init(result: Result<Weather, DomainError>) {
        self.result = result
    }

    var receivedCoordinates: [Coordinate] { received.withLock { $0 } }

    func currentWeather(at coordinate: Coordinate) async throws(DomainError) -> Weather {
        received.withLock { $0.append(coordinate) }
        return try result.get()
    }
}

final class StoryRepositorySpy: StoryRepository {
    struct Call: Equatable { let query: String; let count: Int }

    private let result: Result<[Story], DomainError>
    private let received = Mutex<[Call]>([])

    init(result: Result<[Story], DomainError>) {
        self.result = result
    }

    var calls: [Call] { received.withLock { $0 } }

    func stories(matching query: String, count: Int) async throws(DomainError) -> [Story] {
        received.withLock { $0.append(Call(query: query, count: count)) }
        return try result.get()
    }
}

extension Weather {
    static func fixture(name: String = "Paris", coordinate: Coordinate = .paris) -> Weather {
        Weather(
            locationName: name,
            countryCode: "FR",
            coordinate: coordinate,
            conditions: [.init(id: 800, summary: "Clear", detail: "clear sky", iconCode: "01d")],
            temperature: .init(current: 18.5, feelsLike: 18, min: 16.5, max: 20),
            pressure: 1013,
            humidity: 60,
            wind: .init(speed: 3.1, degrees: 180, gust: nil),
            cloudiness: 0,
            visibility: 10_000,
            sunrise: nil,
            sunset: nil,
            observedAt: Date(timeIntervalSince1970: 1_650_280_800),
            timeZone: TimeZone(secondsFromGMT: 7200)!
        )
    }
}

extension Coordinate {
    static let paris = Coordinate(latitude: 48.8566, longitude: 2.3522)
}

extension Story {
    static func fixture(id: String) -> Story {
        Story(id: id, imageURL: URL(string: "https://example.com/\(id).jpg")!, caption: nil, photographerName: nil)
    }
}
