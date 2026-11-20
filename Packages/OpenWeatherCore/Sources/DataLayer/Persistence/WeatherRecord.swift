//
//  WeatherRecord.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

/// On-disk format of a saved `Weather`.
///
/// A separate type keeps `Domain` free of persistence concerns: the entity can
/// change shape without silently breaking old files. Bump `currentVersion`
/// when the format changes and old files are simply ignored.
struct WeatherRecord: Codable, Equatable {
    static let currentVersion = 1

    struct Condition: Codable, Equatable {
        let id: Int
        let summary: String
        let detail: String
        let iconCode: String
    }

    struct Temperature: Codable, Equatable {
        let current: Double
        let feelsLike: Double
        let min: Double
        let max: Double
    }

    struct Wind: Codable, Equatable {
        let speed: Double
        let degrees: Int?
        let gust: Double?
    }

    let version: Int
    let locationName: String
    let countryCode: String?
    let latitude: Double
    let longitude: Double
    let conditions: [Condition]
    let temperature: Temperature
    let pressure: Int?
    let humidity: Int?
    let wind: Wind?
    let cloudiness: Int?
    let visibility: Int?
    let sunrise: Date?
    let sunset: Date?
    let observedAt: Date
    let timeZone: TimeZone
}

extension WeatherRecord {
    init(_ weather: Weather) {
        version = Self.currentVersion
        locationName = weather.locationName
        countryCode = weather.countryCode
        latitude = weather.coordinate.latitude
        longitude = weather.coordinate.longitude
        conditions = weather.conditions.map {
            Condition(id: $0.id, summary: $0.summary, detail: $0.detail, iconCode: $0.iconCode)
        }
        temperature = Temperature(
            current: weather.temperature.current,
            feelsLike: weather.temperature.feelsLike,
            min: weather.temperature.min,
            max: weather.temperature.max
        )
        pressure = weather.pressure
        humidity = weather.humidity
        wind = weather.wind.map { Wind(speed: $0.speed, degrees: $0.degrees, gust: $0.gust) }
        cloudiness = weather.cloudiness
        visibility = weather.visibility
        sunrise = weather.sunrise
        sunset = weather.sunset
        observedAt = weather.observedAt
        timeZone = weather.timeZone
    }

    func toDomain() -> Weather {
        Weather(
            locationName: locationName,
            countryCode: countryCode,
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            conditions: conditions.map {
                .init(id: $0.id, summary: $0.summary, detail: $0.detail, iconCode: $0.iconCode)
            },
            temperature: .init(
                current: temperature.current,
                feelsLike: temperature.feelsLike,
                min: temperature.min,
                max: temperature.max
            ),
            pressure: pressure,
            humidity: humidity,
            wind: wind.map { .init(speed: $0.speed, degrees: $0.degrees, gust: $0.gust) },
            cloudiness: cloudiness,
            visibility: visibility,
            sunrise: sunrise,
            sunset: sunset,
            observedAt: observedAt,
            timeZone: timeZone
        )
    }
}
