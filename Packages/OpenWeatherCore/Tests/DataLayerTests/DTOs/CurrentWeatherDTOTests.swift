//
//  CurrentWeatherDTOTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Domain
import Foundation
import Testing

@Suite("CurrentWeatherDTO mapping")
struct CurrentWeatherDTOTests {
    private func decode(_ json: String) throws -> CurrentWeatherDTO {
        try JSONDecoder().decode(CurrentWeatherDTO.self, from: Data(json.utf8))
    }

    @Test("Maps a full payload to the domain entity")
    func mapsFullPayload() throws {
        let weather = try decode(Fixtures.currentWeather).toDomain()

        #expect(weather.locationName == "Pantin")
        #expect(weather.countryCode == "FR")
        #expect(weather.coordinate == Coordinate(latitude: 48.8937, longitude: 2.4064))
        #expect(weather.conditions == [.init(id: 800, summary: "Clear", detail: "clear sky", iconCode: "01d")])
        #expect(weather.temperature == .init(current: 18.5, feelsLike: 18, min: 16.5, max: 20))
        #expect(weather.pressure == 1013)
        #expect(weather.humidity == 60)
        #expect(weather.wind == .init(speed: 3.1, degrees: 180, gust: nil))
        #expect(weather.cloudiness == 0)
        #expect(weather.visibility == 10_000)
        #expect(weather.sunrise == Date(timeIntervalSince1970: 1_650_264_000))
        #expect(weather.sunset == Date(timeIntervalSince1970: 1_650_314_400))
        #expect(weather.observedAt == Date(timeIntervalSince1970: 1_650_280_800))
        #expect(weather.timeZone.secondsFromGMT() == 7200)
    }

    @Test("A payload without temperature is rejected")
    func rejectsMissingMain() throws {
        let dto = try decode(Fixtures.currentWeatherWithoutMain)
        #expect(throws: DomainError.invalidResponse) { try dto.toDomain() }
    }

    @Test("An unnamed location falls back to its coordinates")
    func unnamedLocationFallsBack() throws {
        let json = Fixtures.currentWeather.replacingOccurrences(of: "\"Pantin\"", with: "\"\"")
        let weather = try decode(json).toDomain()
        #expect(weather.locationName == "48.89, 2.41")
    }
}
