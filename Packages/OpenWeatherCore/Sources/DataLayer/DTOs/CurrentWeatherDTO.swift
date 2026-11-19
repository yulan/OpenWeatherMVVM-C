//
//  CurrentWeatherDTO.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

/// Mirror of the OpenWeather "current weather" payload. Every field is
/// optional because the provider omits fields freely; required-ness is decided
/// in `toDomain()`, not by the decoder.
struct CurrentWeatherDTO: Decodable, Sendable {
    struct Coord: Decodable, Sendable {
        let lat: Double?
        let lon: Double?
    }

    struct Condition: Decodable, Sendable {
        let id: Int?
        let main: String?
        let description: String?
        let icon: String?
    }

    struct Main: Decodable, Sendable {
        let temp: Double?
        let feelsLike: Double?
        let tempMin: Double?
        let tempMax: Double?
        let pressure: Int?
        let humidity: Int?

        enum CodingKeys: String, CodingKey {
            case temp, pressure, humidity
            case feelsLike = "feels_like"
            case tempMin = "temp_min"
            case tempMax = "temp_max"
        }
    }

    struct Wind: Decodable, Sendable {
        let speed: Double?
        let deg: Int?
        let gust: Double?
    }

    struct Clouds: Decodable, Sendable {
        let all: Int?
    }

    struct Sys: Decodable, Sendable {
        let country: String?
        let sunrise: TimeInterval?
        let sunset: TimeInterval?
    }

    let coord: Coord?
    let weather: [Condition]?
    let main: Main?
    let wind: Wind?
    let clouds: Clouds?
    let sys: Sys?
    let name: String?
    let visibility: Int?
    let dt: TimeInterval?
    /// Shift in seconds from UTC.
    let timezone: Int?
}

extension CurrentWeatherDTO {
    func toDomain() throws(DomainError) -> Weather {
        guard
            let lat = coord?.lat, let lon = coord?.lon,
            let main, let temp = main.temp
        else {
            throw .invalidResponse
        }

        let conditions: [Weather.Condition] = (weather ?? []).compactMap { dto in
            guard let id = dto.id, let icon = dto.icon else { return nil }
            return Weather.Condition(
                id: id,
                summary: dto.main ?? "",
                detail: dto.description ?? dto.main ?? "",
                iconCode: icon
            )
        }

        let wind: Weather.Wind? = self.wind.flatMap { dto in
            dto.speed.map { Weather.Wind(speed: $0, degrees: dto.deg, gust: dto.gust) }
        }

        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return Weather(
            locationName: trimmedName.isEmpty ? Self.formattedCoordinate(lat: lat, lon: lon) : trimmedName,
            countryCode: sys?.country,
            coordinate: Coordinate(latitude: lat, longitude: lon),
            conditions: conditions,
            temperature: .init(
                current: temp,
                feelsLike: main.feelsLike ?? temp,
                min: main.tempMin ?? temp,
                max: main.tempMax ?? temp
            ),
            pressure: main.pressure,
            humidity: main.humidity,
            wind: wind,
            cloudiness: clouds?.all,
            visibility: visibility,
            sunrise: sys?.sunrise.map(Date.init(timeIntervalSince1970:)),
            sunset: sys?.sunset.map(Date.init(timeIntervalSince1970:)),
            observedAt: dt.map(Date.init(timeIntervalSince1970:)) ?? .now,
            timeZone: timezone.flatMap(TimeZone.init(secondsFromGMT:)) ?? .current
        )
    }

    /// Open ocean / unnamed places come back with an empty `name`.
    private static func formattedCoordinate(lat: Double, lon: Double) -> String {
        String(format: "%.2f, %.2f", lat, lon)
    }
}
