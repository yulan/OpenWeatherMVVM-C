//
//  AppConfiguration.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation

/// Secrets are injected at build time from `Configurations/Secrets.xcconfig`
/// (git-ignored) into Info.plist, then read here. Nothing is hard-coded.
struct AppConfiguration: Sendable, Equatable {
    let openWeatherAPIKey: String
    let unsplashAccessKey: String

    init(openWeatherAPIKey: String, unsplashAccessKey: String) {
        self.openWeatherAPIKey = openWeatherAPIKey
        self.unsplashAccessKey = unsplashAccessKey
    }

    init(bundle: Bundle) {
        self.init(infoDictionary: bundle.infoDictionary ?? [:])
        #if DEBUG
        if openWeatherAPIKey.isEmpty || unsplashAccessKey.isEmpty {
            print("⚠️ API keys missing. Copy Configurations/Secrets.example.xcconfig to Secrets.xcconfig.")
        }
        #endif
    }

    init(infoDictionary: [String: Any]) {
        self.init(
            openWeatherAPIKey: Self.value(for: "OpenWeatherAPIKey", in: infoDictionary),
            unsplashAccessKey: Self.value(for: "UnsplashAccessKey", in: infoDictionary)
        )
    }

    private static func value(for key: String, in infoDictionary: [String: Any]) -> String {
        let raw = (infoDictionary[key] as? String) ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // An unresolved build setting reaches us verbatim as "$(NAME)".
        return trimmed.hasPrefix("$(") ? "" : trimmed
    }
}
