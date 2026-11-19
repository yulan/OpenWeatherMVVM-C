//
//  AppConfigurationTests.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation
@testable import OpenWeatherMVVMC
import Testing

@Suite("AppConfiguration")
struct AppConfigurationTests {
    @Test("Reads and trims keys from Info.plist values")
    func readsKeys() {
        let sut = AppConfiguration(infoDictionary: [
            "OpenWeatherAPIKey": "  weather-key \n",
            "UnsplashAccessKey": "unsplash-key",
        ])
        #expect(sut == AppConfiguration(openWeatherAPIKey: "weather-key", unsplashAccessKey: "unsplash-key"))
    }

    @Test("Unresolved build settings and missing keys become empty strings")
    func unresolvedKeys() {
        let sut = AppConfiguration(infoDictionary: ["OpenWeatherAPIKey": "$(OPENWEATHER_API_KEY)"])
        #expect(sut == AppConfiguration(openWeatherAPIKey: "", unsplashAccessKey: ""))
    }

    @Test("The app's Info.plist declares both keys")
    func infoPlistDeclaresKeys() {
        let info = Bundle.main.infoDictionary ?? [:]
        #expect(info["OpenWeatherAPIKey"] != nil)
        #expect(info["UnsplashAccessKey"] != nil)
    }
}
