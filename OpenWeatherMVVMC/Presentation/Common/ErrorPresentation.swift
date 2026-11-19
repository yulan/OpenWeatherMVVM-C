//
//  ErrorPresentation.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Domain
import Foundation

/// What a screen shows when something fails, and how the user can recover.
struct ErrorPresentation: Equatable {
    enum Recovery: Equatable {
        case retry
        case openSettings

        var title: String {
            switch self {
            case .retry: String(localized: L10n.Error.retry)
            case .openSettings: String(localized: L10n.Error.openSettings)
            }
        }
    }

    let title: String
    let message: String
    let symbol: AppSymbol
    let recovery: Recovery
}

extension ErrorPresentation {
    /// `nil` for errors that must not be surfaced (cancellation).
    init?(_ error: DomainError) {
        switch error {
        case .cancelled:
            return nil
        case .locationPermissionDenied:
            self.init(L10n.Error.locationDeniedTitle, L10n.Error.locationDeniedMessage, .locationDenied, .openSettings)
        case .locationUnavailable:
            self.init(L10n.Error.locationUnavailableTitle, L10n.Error.locationUnavailableMessage, .locationUnavailable, .retry)
        case .offline:
            self.init(L10n.Error.offlineTitle, L10n.Error.offlineMessage, .offline, .retry)
        case .unauthorized:
            self.init(L10n.Error.unauthorizedTitle, L10n.Error.unauthorizedMessage, .unauthorized, .retry)
        case let .server(statusCode):
            self.init(L10n.Error.genericTitle, L10n.Error.serverMessage(statusCode), .serverError, .retry)
        case .invalidResponse, .unknown:
            self.init(L10n.Error.genericTitle, L10n.Error.genericMessage, .genericError, .retry)
        }
    }

    init(
        _ title: LocalizedStringResource,
        _ message: LocalizedStringResource,
        _ symbol: AppSymbol,
        _ recovery: Recovery
    ) {
        self.init(title: String(localized: title), message: String(localized: message), symbol: symbol, recovery: recovery)
    }
}
