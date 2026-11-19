//
//  Coordinate.swift
//  Domain
//
//  Created by Lan YU on 19/11/2026.
//

/// A geographic coordinate, deliberately free of CoreLocation so the Domain
/// layer stays framework-agnostic.
public struct Coordinate: Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
