//
//  AppSymbol.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import SwiftUI

/// Every SF Symbol used by the UI, in one place. Weather-condition symbols
/// are data-driven and live in `WeatherSymbol`.
enum AppSymbol: String {
    case appLogo = "cloud.sun.fill"
    case viewStories = "photo.stack"
    case close = "xmark"
    case photoPlaceholder = "photo"
    case sunrise = "sunrise.fill"
    case sunset = "sunset.fill"

    // Metrics
    case feelsLike = "thermometer.medium"
    case humidity = "humidity"
    case wind = "wind"
    case pressure = "gauge.with.dots.needle.33percent"
    case clouds = "cloud"
    case visibility = "eye"

    // Errors
    case locationDenied = "location.slash"
    case locationUnavailable = "location.magnifyingglass"
    case offline = "wifi.slash"
    case unauthorized = "key.slash"
    case serverError = "exclamationmark.icloud"
    case genericError = "exclamationmark.triangle"
    case noPhotos = "photo.on.rectangle.angled"
}

extension Image {
    init(symbol: AppSymbol) {
        self.init(systemName: symbol.rawValue)
    }
}
