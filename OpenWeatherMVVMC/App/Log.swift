//
//  Log.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 20/11/2026.
//

import Foundation
import OSLog

/// Unified logging for the app target. Same subsystem as the Data layer, so
/// `subsystem:YULan.OpenWeatherMVVMC` in Console shows the whole story of a
/// session: request, location, cache fallback, what the user was shown.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "OpenWeatherMVVMC"

    static let images = Logger(subsystem: subsystem, category: "images")
    /// Errors actually presented to the user: the first thing to look at when
    /// someone reports "it says something went wrong".
    static let ui = Logger(subsystem: subsystem, category: "ui")

    static let signposter = OSSignposter(subsystem: subsystem, category: .pointsOfInterest)
}
