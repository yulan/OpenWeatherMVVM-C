//
//  OpenWeatherAPI.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

enum OpenWeatherAPI {
    static let baseURL = URL(string: "https://api.openweathermap.org")!

    /// https://openweathermap.org/current
    static func currentWeather(
        at coordinate: Coordinate,
        apiKey: String,
        languageCode: String
    ) -> Endpoint<CurrentWeatherDTO> {
        Endpoint(
            baseURL: baseURL,
            path: "data/2.5/weather",
            queryItems: [
                URLQueryItem(name: "lat", value: String(coordinate.latitude)),
                URLQueryItem(name: "lon", value: String(coordinate.longitude)),
                // Always metric on purpose: the Domain works in one canonical unit
                // system and the presentation layer converts for the user's locale.
                URLQueryItem(name: "units", value: "metric"),
                URLQueryItem(name: "lang", value: languageCode),
                URLQueryItem(name: "appid", value: apiKey),
            ]
        )
    }
}
