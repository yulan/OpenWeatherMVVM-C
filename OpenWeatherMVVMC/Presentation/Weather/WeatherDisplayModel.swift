//
//  WeatherDisplayModel.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

/// Fully formatted, view-ready representation of `Weather`. Pure value type:
/// all formatting decisions live here and are unit-tested with a fixed locale.
struct WeatherDisplayModel: Equatable {
    struct Metric: Identifiable, Equatable {
        var id: String { title }
        let title: String
        let value: String
        let symbol: AppSymbol
    }

    let date: String
    /// "Updated 2 hours ago": makes data served from the offline cache visible.
    let lastUpdated: String
    let locationName: String
    let symbolName: String
    let temperature: String
    let conditionDescription: String
    let highLow: String
    let metrics: [Metric]
    let sunrise: String?
    let sunset: String?
    let isNight: Bool
}

extension WeatherDisplayModel {
    init(weather: Weather, locale: Locale, now: Date) {
        let condition = weather.primaryCondition
        let fmt = Formatter(locale: locale, timeZone: weather.timeZone)

        date = fmt.date(weather.observedAt)
        lastUpdated = L10n.Weather.updated(fmt.relative(weather.observedAt, to: now)).resolved(in: locale)
        locationName = [weather.locationName, weather.countryCode]
            .compactMap { $0 }
            .joined(separator: ", ")
        symbolName = WeatherSymbol.name(forIconCode: condition?.iconCode)
        temperature = fmt.temperature(weather.temperature.current)
        conditionDescription = condition.map { fmt.sentenceCase($0.detail) } ?? ""
        highLow = L10n.Weather.highLow(
            high: fmt.temperature(weather.temperature.max),
            low: fmt.temperature(weather.temperature.min)
        ).resolved(in: locale)
        isNight = condition?.isNight ?? false
        sunrise = weather.sunrise.map(fmt.time)
        sunset = weather.sunset.map(fmt.time)

        typealias M = L10n.Weather.Metric
        func metric(_ title: LocalizedStringResource, _ value: String, _ symbol: AppSymbol) -> Metric {
            Metric(title: title.resolved(in: locale), value: value, symbol: symbol)
        }
        var metrics = [metric(M.feelsLike, fmt.temperature(weather.temperature.feelsLike), .feelsLike)]
        if let humidity = weather.humidity {
            metrics.append(metric(M.humidity, fmt.percent(humidity), .humidity))
        }
        if let wind = weather.wind {
            let direction = wind.degrees.map { " " + CompassDirection(degrees: $0).abbreviation } ?? ""
            metrics.append(metric(M.wind, fmt.speed(wind.speed) + direction, .wind))
        }
        if let pressure = weather.pressure {
            metrics.append(metric(M.pressure, "\(fmt.integer(pressure)) hPa", .pressure))
        }
        if let cloudiness = weather.cloudiness {
            metrics.append(metric(M.clouds, fmt.percent(cloudiness), .clouds))
        }
        if let visibility = weather.visibility {
            metrics.append(metric(M.visibility, fmt.distance(meters: visibility), .visibility))
        }
        self.metrics = metrics
    }

    /// Plausible content for the redacted loading skeleton.
    static let placeholder = WeatherDisplayModel(
        date: "Monday 1 January",
        lastUpdated: "Updated 10 minutes ago",
        locationName: "Placeholder City",
        symbolName: "cloud.sun.fill",
        temperature: "20°",
        conditionDescription: "Partly cloudy",
        highLow: "H:22°  L:14°",
        // Redacted while shown: wording is never visible, only the shapes.
        metrics: [AppSymbol.feelsLike, .humidity, .wind, .pressure, .clouds, .visibility].map {
            Metric(title: "Placeholder", value: "00 unit", symbol: $0)
        },
        sunrise: "06:00",
        sunset: "20:00",
        isNight: false
    )
}

// MARK: - Formatting helpers

private struct Formatter {
    let locale: Locale
    let timeZone: TimeZone

    func temperature(_ celsius: Double) -> String {
        // Avoid "-0°" for values in (-0.5, 0).
        let rounded = celsius.rounded()
        return integer(rounded == 0 ? 0 : Int(rounded)) + "°"
    }

    /// "ciel dégagé" → "Ciel dégagé". Title Case ("Ciel Dégagé") is an English
    /// convention and looks wrong in most other languages.
    func sentenceCase(_ text: String) -> String {
        guard let first = text.first else { return text }
        return String(first).uppercased(with: locale) + text.dropFirst()
    }

    func integer(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    func percent(_ value: Int) -> String {
        "\(integer(value))%"
    }

    func speed(_ metersPerSecond: Double) -> String {
        metersPerSecond.formatted(.number.precision(.fractionLength(0...1)).locale(locale)) + " m/s"
    }

    func distance(meters: Int) -> String {
        guard meters >= 1000 else { return "\(integer(meters)) m" }
        let km = Double(meters) / 1000
        return km.formatted(.number.precision(.fractionLength(0...1)).locale(locale)) + " km"
    }

    func time(_ date: Date) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.locale = locale
        style.timeZone = timeZone
        return date.formatted(style)
    }

    /// "2 hours ago". A provider clock slightly ahead of ours reads as "now",
    /// never as "in 2 minutes".
    func relative(_ date: Date, to now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter.localizedString(for: min(date, now), relativeTo: now)
    }

    func date(_ date: Date) -> String {
        var style = Date.FormatStyle().weekday(.wide).day().month(.wide)
        style.locale = locale
        style.timeZone = timeZone
        return date.formatted(style)
    }
}

// MARK: - Symbols & compass

enum WeatherSymbol {
    /// Maps OpenWeather icon codes (https://openweathermap.org/weather-conditions)
    /// to SF Symbols, including night variants.
    static func name(forIconCode code: String?) -> String {
        switch code {
        case "01d": "sun.max.fill"
        case "01n": "moon.stars.fill"
        case "02d": "cloud.sun.fill"
        case "02n": "cloud.moon.fill"
        case "03d", "03n": "cloud.fill"
        case "04d", "04n": "smoke.fill"
        case "09d", "09n": "cloud.drizzle.fill"
        case "10d": "cloud.sun.rain.fill"
        case "10n": "cloud.moon.rain.fill"
        case "11d", "11n": "cloud.bolt.rain.fill"
        case "13d", "13n": "snowflake"
        case "50d", "50n": "cloud.fog.fill"
        default: "cloud.sun.fill"
        }
    }
}

enum CompassDirection: Int, CaseIterable {
    case north, northEast, east, southEast, south, southWest, west, northWest

    init(degrees: Int) {
        let normalized = ((degrees % 360) + 360) % 360
        self = Self(rawValue: Int((Double(normalized) + 22.5) / 45) % 8)!
    }

    var abbreviation: String {
        switch self {
        case .north: "N"
        case .northEast: "NE"
        case .east: "E"
        case .southEast: "SE"
        case .south: "S"
        case .southWest: "SW"
        case .west: "W"
        case .northWest: "NW"
        }
    }
}
