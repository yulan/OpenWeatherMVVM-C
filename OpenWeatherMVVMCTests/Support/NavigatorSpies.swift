//
//  NavigatorSpies.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation
@testable import OpenWeatherMVVMC

@MainActor
final class WeatherNavigatorSpy: WeatherNavigating {
    private(set) var shownStoriesCities: [String] = []
    private(set) var openAppSettingsCount = 0

    func showStories(for city: String) { shownStoriesCities.append(city) }
    func openAppSettings() { openAppSettingsCount += 1 }
}

@MainActor
final class StoriesNavigatorSpy: StoriesNavigating {
    private(set) var closeCount = 0

    func closeStories() { closeCount += 1 }
}

@MainActor
final class URLOpenerSpy: URLOpening {
    private(set) var openedURLs: [URL] = []

    func open(_ url: URL) { openedURLs.append(url) }
}
