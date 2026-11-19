//
//  L10n.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation

/// Every user-facing string, keyed into `Localizable.xcstrings` (en, fr).
/// Views and ViewModels never contain raw wording.
enum L10n {
    enum Splash {
        static let title = LocalizedStringResource("splash.title", defaultValue: "Open Weather")
        static let poweredBy = LocalizedStringResource("splash.poweredBy", defaultValue: "Powered by OpenWeather")
    }

    enum Weather {
        static let loading = LocalizedStringResource("weather.loading.a11y", defaultValue: "Loading weather")
        static let viewStories = LocalizedStringResource("weather.stories.button", defaultValue: "View Stories")
        static func viewStoriesHint(_ city: String) -> LocalizedStringResource {
            LocalizedStringResource("weather.stories.hint", defaultValue: "Shows photos of \(city)")
        }
        static func highLow(high: String, low: String) -> LocalizedStringResource {
            LocalizedStringResource("weather.highLow", defaultValue: "H:\(high)  L:\(low)")
        }
        static func sunrise(_ time: String) -> LocalizedStringResource {
            LocalizedStringResource("weather.sunrise.a11y", defaultValue: "Sunrise \(time)")
        }
        static func sunset(_ time: String) -> LocalizedStringResource {
            LocalizedStringResource("weather.sunset.a11y", defaultValue: "Sunset \(time)")
        }

        enum Metric {
            static let feelsLike = LocalizedStringResource("weather.metric.feelsLike", defaultValue: "Feels Like")
            static let humidity = LocalizedStringResource("weather.metric.humidity", defaultValue: "Humidity")
            static let wind = LocalizedStringResource("weather.metric.wind", defaultValue: "Wind")
            static let pressure = LocalizedStringResource("weather.metric.pressure", defaultValue: "Pressure")
            static let clouds = LocalizedStringResource("weather.metric.clouds", defaultValue: "Clouds")
            static let visibility = LocalizedStringResource("weather.metric.visibility", defaultValue: "Visibility")
        }
    }

    enum Stories {
        static let close = LocalizedStringResource("stories.close.a11y", defaultValue: "Close")
        static let next = LocalizedStringResource("stories.next.a11y", defaultValue: "Next")
        static let previous = LocalizedStringResource("stories.previous.a11y", defaultValue: "Previous")
        static func photoOf(_ city: String) -> LocalizedStringResource {
            LocalizedStringResource("stories.photo.a11y", defaultValue: "Photo of \(city)")
        }
        static func attribution(_ photographer: String) -> LocalizedStringResource {
            LocalizedStringResource("stories.attribution", defaultValue: "Photo by \(photographer) on Unsplash")
        }
        static let emptyTitle = LocalizedStringResource("stories.empty.title", defaultValue: "No Stories")
        static func emptyMessage(_ city: String) -> LocalizedStringResource {
            LocalizedStringResource("stories.empty.message", defaultValue: "We couldn't find photos of \(city).")
        }
    }

    enum Error {
        static let retry = LocalizedStringResource("error.recovery.retry", defaultValue: "Try Again")
        static let openSettings = LocalizedStringResource("error.recovery.openSettings", defaultValue: "Open Settings")
        static let dismiss = LocalizedStringResource("error.dismiss", defaultValue: "OK")

        static let locationDeniedTitle = LocalizedStringResource("error.locationDenied.title", defaultValue: "Location Access Needed")
        static let locationDeniedMessage = LocalizedStringResource("error.locationDenied.message", defaultValue: "Allow location access in Settings to see the weather where you are.")
        static let locationUnavailableTitle = LocalizedStringResource("error.locationUnavailable.title", defaultValue: "Can't Find Your Location")
        static let locationUnavailableMessage = LocalizedStringResource("error.locationUnavailable.message", defaultValue: "Make sure Location Services are on, then try again.")
        static let offlineTitle = LocalizedStringResource("error.offline.title", defaultValue: "You're Offline")
        static let offlineMessage = LocalizedStringResource("error.offline.message", defaultValue: "Check your internet connection and try again.")
        static let unauthorizedTitle = LocalizedStringResource("error.unauthorized.title", defaultValue: "Service Unavailable")
        static let unauthorizedMessage = LocalizedStringResource("error.unauthorized.message", defaultValue: "The request was rejected. Check the API keys in Secrets.xcconfig.")
        static let genericTitle = LocalizedStringResource("error.generic.title", defaultValue: "Something Went Wrong")
        static let genericMessage = LocalizedStringResource("error.generic.message", defaultValue: "We couldn't load this content. Please try again.")
        static func serverMessage(_ statusCode: Int) -> LocalizedStringResource {
            LocalizedStringResource("error.server.message", defaultValue: "The service returned an error (\(statusCode)). Please try again later.")
        }
    }
}

extension LocalizedStringResource {
    /// Resolves wording in the same locale used for number/date formatting,
    /// so a display model never mixes languages (and stays testable).
    func resolved(in locale: Locale) -> String {
        var resource = self
        resource.locale = locale
        return String(localized: resource)
    }
}
