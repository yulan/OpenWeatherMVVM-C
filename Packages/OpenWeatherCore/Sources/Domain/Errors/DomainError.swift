//
//  DomainError.swift
//  Domain
//
//  Created by Lan YU on 19/11/2026.
//

/// The closed set of failures the Presentation layer has to handle.
///
/// Infrastructure errors (`URLError`, `DecodingError`, CoreLocation states…)
/// never leak past the Data layer; they are translated into one of these cases
/// so ViewModels can switch exhaustively.
public enum DomainError: Error, Equatable, Sendable {
    case locationPermissionDenied
    case locationUnavailable
    case offline
    case unauthorized
    case server(statusCode: Int)
    case invalidResponse
    case cancelled
    case unknown
}
