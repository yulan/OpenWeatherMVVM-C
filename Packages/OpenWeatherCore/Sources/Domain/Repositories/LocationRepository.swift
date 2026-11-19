//
//  LocationRepository.swift
//  Domain
//
//  Created by Lan YU on 19/11/2026.
//

public protocol LocationRepository: Sendable {
    /// Resolves the device's current position, requesting authorization if needed.
    func currentCoordinate() async throws(DomainError) -> Coordinate
}
