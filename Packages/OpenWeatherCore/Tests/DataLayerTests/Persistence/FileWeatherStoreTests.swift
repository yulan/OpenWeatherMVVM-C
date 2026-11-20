//
//  FileWeatherStoreTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 19/11/2026.
//

@testable import DataLayer
import Domain
import Foundation
import Testing

@Suite("FileWeatherStore")
struct FileWeatherStoreTests {
    /// A fresh, not-yet-created directory per test, so tests can run in parallel.
    private let fileURL = URL.temporaryDirectory
        .appending(path: "FileWeatherStoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        .appending(path: "weather.json")

    @Test("Round-trips every field, including optionals and the time zone")
    func roundTrip() throws {
        let sut = FileWeatherStore(fileURL: fileURL)
        let weather = Weather.fixture()

        try sut.save(weather)

        #expect(sut.lastWeather() == weather)
    }

    @Test("Round-trips missing optional values")
    func roundTripWithoutWind() throws {
        let sut = FileWeatherStore(fileURL: fileURL)
        let weather = Weather.fixture(wind: nil)

        try sut.save(weather)

        #expect(sut.lastWeather() == weather)
    }

    @Test("Saving again replaces the previous weather")
    func overwrites() throws {
        let sut = FileWeatherStore(fileURL: fileURL)

        try sut.save(.fixture(name: "First"))
        try sut.save(.fixture(name: "Second"))

        #expect(sut.lastWeather()?.locationName == "Second")
    }

    @Test("No file yet is a cache miss")
    func missingFile() {
        #expect(FileWeatherStore(fileURL: fileURL).lastWeather() == nil)
    }

    @Test("A corrupt file is a cache miss, not a crash")
    func corruptFile() throws {
        try write(Data("not json".utf8))

        #expect(FileWeatherStore(fileURL: fileURL).lastWeather() == nil)
    }

    @Test("A file written in another format version is ignored")
    func otherVersionIgnored() throws {
        let sut = FileWeatherStore(fileURL: fileURL)
        try sut.save(.fixture())
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as! [String: Any]
        json["version"] = WeatherRecord.currentVersion + 1
        try write(JSONSerialization.data(withJSONObject: json))

        #expect(sut.lastWeather() == nil)
    }

    private func write(_ data: Data) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL)
    }
}
