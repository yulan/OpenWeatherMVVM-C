//
//  Log.swift
//  DataLayer
//
//  Created by Lan YU on 20/11/2026.
//

import Foundation
import OSLog

/// Unified logging for the Data layer.
///
/// The subsystem is the host app's bundle identifier, so one Console filter
/// (`subsystem:YULan.OpenWeatherMVVMC`) shows every layer together. Values are
/// `.private` unless marked otherwise: coordinates and API keys never reach
/// the log in clear text.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "OpenWeatherCore"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let location = Logger(subsystem: subsystem, category: "location")
    static let cache = Logger(subsystem: subsystem, category: "cache")

    /// Intervals visible in Instruments (os_signpost): "HTTP request", "Location fix".
    static let signposter = OSSignposter(subsystem: subsystem, category: .pointsOfInterest)
}
