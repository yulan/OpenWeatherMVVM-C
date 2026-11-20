//
//  CoreLocationRepository.swift
//  DataLayer
//
//  Created by Lan YU on 19/11/2026.
//

import CoreLocation
import Domain

/// Resolves a one-shot location fix using the iOS 18 CoreLocation API
/// (`CLServiceSession` + `CLLocationUpdate.liveUpdates()`), which replaces the
/// delegate / continuation dance and is safe under strict concurrency.
public struct CoreLocationRepository: LocationRepository {
    private let timeout: Duration

    public init(timeout: Duration = .seconds(15)) {
        self.timeout = timeout
    }

    public func currentCoordinate() async throws(DomainError) -> Coordinate {
        let signpost = Log.signposter.beginInterval("Location fix", id: Log.signposter.makeSignpostID())
        defer { Log.signposter.endInterval("Location fix", signpost) }

        do {
            return try await withWatchdog(Watchdog(timeout: timeout)) { watchdog in
                try await Self.firstFix(watchdog: watchdog)
            }
        } catch let error as DomainError {
            Log.location.notice("No location: \(String(describing: error), privacy: .public)")
            throw error
        } catch is CancellationError {
            throw .cancelled
        } catch {
            Log.location.error("No location fix within \(self.timeout, privacy: .public)")
            throw .locationUnavailable
        }
    }

    private static func firstFix(watchdog: Watchdog) async throws -> Coordinate {
        #if !os(macOS)
        // Holding a session for the duration of the request is what triggers the
        // When-In-Use prompt and keeps updates flowing. (macOS only exists here so
        // the package can be unit-tested natively with `swift test`.)
        let session = CLServiceSession(authorization: .whenInUse)
        defer { session.invalidate() }
        #endif

        for try await update in CLLocationUpdate.liveUpdates() {
            // The timeout measures "waiting for GPS", not "waiting for the user
            // to answer the permission prompt".
            if update.authorizationRequestInProgress {
                watchdog.suspend()
            } else {
                watchdog.resume()
            }

            if let location = update.location {
                return Coordinate(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
            if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted {
                throw DomainError.locationPermissionDenied
            }
            // `locationUnavailable`: keep waiting until a fix arrives or the watchdog fires.
        }
        throw DomainError.locationUnavailable
    }
}
