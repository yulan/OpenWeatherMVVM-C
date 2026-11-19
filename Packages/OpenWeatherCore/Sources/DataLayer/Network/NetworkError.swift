//
//  NetworkError.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

public enum NetworkError: Error, Equatable, Sendable {
    case invalidRequest
    case transport(URLError.Code)
    case httpStatus(Int)
    case decoding(String)
    case cancelled
}

extension NetworkError {
    private static let connectivityCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .timedOut,
        .cannotFindHost,
        .cannotConnectToHost,
        .dnsLookupFailed,
        .dataNotAllowed,
        .internationalRoamingOff,
    ]

    /// Translates transport-level failures into the vocabulary of the Domain.
    var domainError: DomainError {
        switch self {
        case .cancelled:
            .cancelled
        case let .transport(code) where Self.connectivityCodes.contains(code):
            .offline
        case .transport:
            .unknown
        case .httpStatus(401), .httpStatus(403):
            .unauthorized
        case let .httpStatus(code):
            .server(statusCode: code)
        case .decoding:
            .invalidResponse
        case .invalidRequest:
            .unknown
        }
    }
}
