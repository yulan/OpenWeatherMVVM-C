//
//  UITestLaunch.swift
//  OpenWeatherMVVMC
//
//  Created by Lan YU on 19/11/2026.
//

import Foundation

/// Launch contract between the UI tests and the app: the test passes a
/// scenario in the environment; DEBUG builds swap in deterministic stubs.
enum UITestLaunch {
    static let scenarioKey = "UITEST_SCENARIO"

    enum Scenario: String, CaseIterable {
        case weatherSuccess
        case permissionDenied
        case offlineThenSuccess
    }

    static func scenario(in environment: [String: String]) -> Scenario? {
        environment[scenarioKey].flatMap(Scenario.init(rawValue:))
    }
}
