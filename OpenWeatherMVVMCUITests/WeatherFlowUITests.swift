//
//  WeatherFlowUITests.swift
//  OpenWeatherMVVMCUITests
//
//  Created by Lan YU on 19/11/2026.
//

import XCTest

/// End-to-end flows against deterministic stubs (see `UITestLaunch`).
/// Elements are found by accessibility identifier, never by wording, so the
/// tests pass in any language.
@MainActor
final class WeatherFlowUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func launch(_ scenario: UITestLaunch.Scenario) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment[UITestLaunch.scenarioKey] = scenario.rawValue
        app.launch()
        return app
    }

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }

    func testShowsWeatherThenOpensAndClosesStories() {
        let app = launch(.weatherSuccess)

        let header = element(AccessibilityID.Weather.header, in: app)
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertTrue(header.label.contains("Paris"), "Header label: \(header.label)")

        element(AccessibilityID.Weather.storiesButton, in: app).tap()
        let close = element(AccessibilityID.Stories.closeButton, in: app)
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertTrue(element(AccessibilityID.Stories.page, in: app).waitForExistence(timeout: 5))

        close.tap()
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertFalse(close.exists)
    }

    func testPermissionDeniedOffersSettings() {
        let app = launch(.permissionDenied)

        XCTAssertTrue(element(AccessibilityID.ErrorState.view, in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(element(AccessibilityID.ErrorState.recoveryButton, in: app).exists)
        XCTAssertFalse(element(AccessibilityID.Weather.header, in: app).exists)
    }

    func testRetryAfterOfflineLoadsWeather() {
        let app = launch(.offlineThenSuccess)

        let retry = element(AccessibilityID.ErrorState.recoveryButton, in: app)
        XCTAssertTrue(retry.waitForExistence(timeout: 5))
        retry.tap()

        XCTAssertTrue(element(AccessibilityID.Weather.header, in: app).waitForExistence(timeout: 5))
    }
}
