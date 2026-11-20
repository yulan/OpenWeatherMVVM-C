//
//  CachedWeatherRepository.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

/// Decorator over any `WeatherRepository`: saves every successful result and,
/// when the device is offline, serves the last one instead of failing.
///
/// The use case and the ViewModel don't know it exists. The UI stays honest
/// because it shows how old the data is (`Weather.observedAt`).
public struct CachedWeatherRepository: WeatherRepository {
    /// When saved weather is still worth showing.
    public struct Policy: Sendable {
        public var maxAge: Duration
        /// Saved weather for another city would be wrong, not just stale.
        public var maxDistanceInMeters: Double

        public init(maxAge: Duration, maxDistanceInMeters: Double) {
            self.maxAge = maxAge
            self.maxDistanceInMeters = maxDistanceInMeters
        }

        public static let `default` = Policy(maxAge: .seconds(24 * 60 * 60), maxDistanceInMeters: 25_000)
    }

    private let remote: any WeatherRepository
    private let store: any WeatherStore
    private let policy: Policy
    private let now: @Sendable () -> Date

    public init(
        remote: any WeatherRepository,
        store: any WeatherStore,
        policy: Policy = .default,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.remote = remote
        self.store = store
        self.policy = policy
        self.now = now
    }

    public func currentWeather(at coordinate: Coordinate) async throws(DomainError) -> Weather {
        do {
            let weather = try await remote.currentWeather(at: coordinate)
            // Best effort: a full disk must not turn a successful request into an error.
            try? store.save(weather)
            return weather
        } catch {
            // Only connectivity problems fall back. A bad API key or a server
            // error must stay visible, not be hidden behind old data.
            guard error == .offline, let saved = store.lastWeather(), isUsable(saved, at: coordinate) else {
                throw error
            }
            return saved
        }
    }

    private func isUsable(_ saved: Weather, at coordinate: Coordinate) -> Bool {
        let age = now().timeIntervalSince(saved.observedAt)
        let maxAge = Double(policy.maxAge.components.seconds)
        return age <= maxAge && saved.coordinate.distance(to: coordinate) <= policy.maxDistanceInMeters
    }
}

extension Coordinate {
    /// Great-circle (haversine) distance in meters.
    func distance(to other: Coordinate) -> Double {
        let earthRadius = 6_371_000.0
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let deltaLat = (other.latitude - latitude) * .pi / 180
        let deltaLon = (other.longitude - longitude) * .pi / 180
        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
