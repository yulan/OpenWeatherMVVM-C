//
//  WeatherStore.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

/// Keeps the last successfully fetched weather.
public protocol WeatherStore: Sendable {
    /// `nil` when nothing was saved, or the saved file can't be read any more.
    func lastWeather() -> Weather?
    func save(_ weather: Weather) throws
}

/// One JSON file, written atomically. It lives in Caches: the system may purge
/// it, which is fine for data we can always fetch again.
public struct FileWeatherStore: WeatherStore {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// `Library/Caches/OpenWeather/last-weather.json`
    public static func inCachesDirectory() -> FileWeatherStore {
        let caches = URL.cachesDirectory.appending(path: "OpenWeather", directoryHint: .isDirectory)
        return FileWeatherStore(fileURL: caches.appending(path: "last-weather.json"))
    }

    public func lastWeather() -> Weather? {
        // A missing, corrupt or older-format file is a cache miss, never an error.
        guard
            let data = try? Data(contentsOf: fileURL),
            let record = try? JSONDecoder().decode(WeatherRecord.self, from: data),
            record.version == WeatherRecord.currentVersion
        else { return nil }
        return record.toDomain()
    }

    public func save(_ weather: Weather) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder().encode(WeatherRecord(weather)).write(to: fileURL, options: .atomic)
    }
}
