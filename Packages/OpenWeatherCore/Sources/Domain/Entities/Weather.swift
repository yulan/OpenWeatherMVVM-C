//
//  Weather.swift
//  Domain
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation

/// Current weather conditions for a place.
///
/// Units are normalised by the Data layer: temperatures in °C, speeds in m/s,
/// pressure in hPa, visibility in metres.
public struct Weather: Equatable, Sendable {
    public struct Condition: Equatable, Sendable {
        public let id: Int
        public let summary: String
        public let detail: String
        /// Provider icon code, e.g. `"01d"`. The trailing `d`/`n` encodes day or night.
        public let iconCode: String

        public var isNight: Bool { iconCode.hasSuffix("n") }

        public init(id: Int, summary: String, detail: String, iconCode: String) {
            self.id = id
            self.summary = summary
            self.detail = detail
            self.iconCode = iconCode
        }
    }

    public struct Temperature: Equatable, Sendable {
        public let current: Double
        public let feelsLike: Double
        public let min: Double
        public let max: Double

        public init(current: Double, feelsLike: Double, min: Double, max: Double) {
            self.current = current
            self.feelsLike = feelsLike
            self.min = min
            self.max = max
        }
    }

    public struct Wind: Equatable, Sendable {
        public let speed: Double
        public let degrees: Int?
        public let gust: Double?

        public init(speed: Double, degrees: Int?, gust: Double?) {
            self.speed = speed
            self.degrees = degrees
            self.gust = gust
        }
    }

    public let locationName: String
    public let countryCode: String?
    public let coordinate: Coordinate
    public let conditions: [Condition]
    public let temperature: Temperature
    public let pressure: Int?
    public let humidity: Int?
    public let wind: Wind?
    public let cloudiness: Int?
    public let visibility: Int?
    public let sunrise: Date?
    public let sunset: Date?
    public let observedAt: Date
    /// Time zone of the observed location (not the device), used to display
    /// sunrise/sunset in local time.
    public let timeZone: TimeZone

    public var primaryCondition: Condition? { conditions.first }

    public init(
        locationName: String,
        countryCode: String?,
        coordinate: Coordinate,
        conditions: [Condition],
        temperature: Temperature,
        pressure: Int?,
        humidity: Int?,
        wind: Wind?,
        cloudiness: Int?,
        visibility: Int?,
        sunrise: Date?,
        sunset: Date?,
        observedAt: Date,
        timeZone: TimeZone
    ) {
        self.locationName = locationName
        self.countryCode = countryCode
        self.coordinate = coordinate
        self.conditions = conditions
        self.temperature = temperature
        self.pressure = pressure
        self.humidity = humidity
        self.wind = wind
        self.cloudiness = cloudiness
        self.visibility = visibility
        self.sunrise = sunrise
        self.sunset = sunset
        self.observedAt = observedAt
        self.timeZone = timeZone
    }
}
