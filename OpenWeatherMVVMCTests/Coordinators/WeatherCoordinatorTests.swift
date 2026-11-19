//
//  WeatherCoordinatorTests.swift
//  OpenWeatherMVVMCTests
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation
@testable import OpenWeatherMVVMC
import Testing
import UIKit

@MainActor
@Suite("WeatherCoordinator")
struct WeatherCoordinatorTests {
    @Test("Wires itself as the weather screen's navigator")
    func wiresNavigator() {
        let sut = WeatherCoordinator(container: .stub())
        #expect(sut.weatherViewModel.navigator === sut)
    }

    @Test("Tapping stories on the weather screen presents stories for that city")
    func showStoriesEndToEnd() async throws {
        let sut = WeatherCoordinator(container: .stub(weather: .fixture(name: "Nice")))

        await sut.weatherViewModel.onAppear()
        sut.weatherViewModel.storiesTapped()

        guard case let .stories(stories) = try #require(sut.destination) else { return }
        #expect(stories.city == "Nice")
        #expect(stories.navigator === sut)
    }

    @Test("Presenting stories twice keeps the first presentation")
    func showStoriesIsIdempotent() throws {
        let sut = WeatherCoordinator(container: .stub())

        sut.showStories(for: "Paris")
        let first = try #require(sut.destination).id
        sut.showStories(for: "Lyon")

        #expect(sut.destination?.id == first)
    }

    @Test("Closing stories dismisses the presentation")
    func closeStories() throws {
        let sut = WeatherCoordinator(container: .stub())
        sut.showStories(for: "Paris")
        guard case let .stories(stories) = try #require(sut.destination) else { return }

        stories.close()

        #expect(sut.destination == nil)
    }

    @Test("Opening settings opens the app's Settings page")
    func openSettings() {
        let urlOpener = URLOpenerSpy()
        let sut = WeatherCoordinator(container: .stub(urlOpener: urlOpener))

        sut.openAppSettings()

        #expect(urlOpener.openedURLs == [URL(string: UIApplication.openSettingsURLString)!])
    }
}
