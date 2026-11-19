//
//  Fixtures.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

extension Weather {
    static func fixture(
        name: String = "Paris",
        iconCode: String = "01d",
        temperature: Double = 18.5,
        timeZone: TimeZone = TimeZone(secondsFromGMT: 7200)!
    ) -> Weather {
        Weather(
            locationName: name,
            countryCode: "FR",
            coordinate: Coordinate(latitude: 48.8566, longitude: 2.3522),
            conditions: [.init(id: 800, summary: "Clear", detail: "clear sky", iconCode: iconCode)],
            temperature: .init(current: temperature, feelsLike: 18.0, min: 16.5, max: 20.0),
            pressure: 1013,
            humidity: 60,
            wind: .init(speed: 3.1, degrees: 180, gust: nil),
            cloudiness: 0,
            visibility: 10_000,
            // 2022-04-18 06:40 / 20:40 UTC
            sunrise: Date(timeIntervalSince1970: 1_650_264_000),
            sunset: Date(timeIntervalSince1970: 1_650_314_400),
            observedAt: Date(timeIntervalSince1970: 1_650_280_800),
            timeZone: timeZone
        )
    }
}

extension Story {
    static func fixture(_ id: String) -> Story {
        Story(id: id, imageURL: URL(string: "https://example.com/\(id).jpg")!, caption: nil, photographerName: nil)
    }

    static let fixtures: [Story] = ["1", "2", "3"].map(fixture)
}

extension Locale {
    static let testLocale = Locale(identifier: "en_GB")
}
