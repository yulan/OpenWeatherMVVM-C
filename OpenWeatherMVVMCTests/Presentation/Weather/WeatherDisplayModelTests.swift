//
//  WeatherDisplayModelTests.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation
@testable import OpenWeatherMVVMC
import Testing

@Suite("WeatherDisplayModel")
struct WeatherDisplayModelTests {
    @Test("Formats the headline values")
    func headline() {
        let sut = WeatherDisplayModel(weather: .fixture(), locale: .testLocale)

        #expect(sut.locationName == "Paris, FR")
        #expect(sut.temperature == "19°")
        #expect(sut.conditionDescription == "Clear sky")
        #expect(sut.highLow == "H:20°  L:17°")
        #expect(sut.symbolName == "sun.max.fill")
        #expect(sut.isNight == false)
    }

    @Test("Formats the date and sun times in the location's time zone, not the device's")
    func timesUseLocationTimeZone() {
        let utcPlus2 = WeatherDisplayModel(weather: .fixture(timeZone: TimeZone(secondsFromGMT: 7200)!), locale: .testLocale)
        let utc = WeatherDisplayModel(weather: .fixture(timeZone: TimeZone(secondsFromGMT: 0)!), locale: .testLocale)

        #expect(utcPlus2.date == "Monday 18 April")
        #expect(utcPlus2.sunrise == "8:40")
        #expect(utcPlus2.sunset == "22:40")
        #expect(utc.sunrise == "6:40")
    }

    @Test("Builds the metric tiles")
    func metrics() {
        let sut = WeatherDisplayModel(weather: .fixture(), locale: .testLocale)

        #expect(sut.metrics.map(\.title) == ["Feels Like", "Humidity", "Wind", "Pressure", "Clouds", "Visibility"])
        #expect(sut.metrics.map(\.value) == ["18°", "60%", "3.1 m/s S", "1,013 hPa", "0%", "10 km"])
        #expect(sut.metrics.map(\.symbol) == [.feelsLike, .humidity, .wind, .pressure, .clouds, .visibility])
    }

    @Test("Never displays negative zero", arguments: [-0.4, -0.0, 0.3])
    func noNegativeZero(temperature: Double) {
        let sut = WeatherDisplayModel(weather: .fixture(temperature: temperature), locale: .testLocale)
        #expect(sut.temperature == "0°")
    }

    @Test("Night icon codes switch to the night theme")
    func night() {
        let sut = WeatherDisplayModel(weather: .fixture(iconCode: "01n"), locale: .testLocale)
        #expect(sut.isNight)
        #expect(sut.symbolName == "moon.stars.fill")
    }

    @Test("Maps icon codes to SF Symbols", arguments: [
        ("01d", "sun.max.fill"),
        ("02n", "cloud.moon.fill"),
        ("04d", "smoke.fill"),
        ("10d", "cloud.sun.rain.fill"),
        ("11n", "cloud.bolt.rain.fill"),
        ("13d", "snowflake"),
        ("50n", "cloud.fog.fill"),
        ("99x", "cloud.sun.fill"),
    ])
    func symbols(code: String, symbol: String) {
        #expect(WeatherSymbol.name(forIconCode: code) == symbol)
    }

    @Test("Converts degrees to compass points", arguments: [
        (0, "N"), (22, "N"), (23, "NE"), (90, "E"), (180, "S"),
        (225, "SW"), (337, "NW"), (338, "N"), (360, "N"), (-90, "W"), (720, "N"),
    ])
    func compass(degrees: Int, expected: String) {
        #expect(CompassDirection(degrees: degrees).abbreviation == expected)
    }
}
